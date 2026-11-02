# Cereal demand demo for AREC 570 / ECON 530, Lecture 6.2
#
# Estimates demand for ready-to-eat cereal in steps, computes what the estimates
# imply for substitution and costs, then simulates a merger.
# The data are the simulated ("fake") data from Nevo (2000, Journal of Economics
# and Management Strategy), which ship with PyBLP (Conlon and Gortmaker 2020).
# Nevo writes that these data are "not real and should not be used for any
# analysis." They are for learning the method.
#
# Setup instructions for VS Code are on the demo page.
# Install once:  pip install pyblp pandas
# Run:           python cereal-demand-demo.py
# Run time:      under one minute on a laptop.

import numpy as np
import pandas as pd
import pyblp

pyblp.options.verbose = False

# One row is a product in a market. A market is a city in a quarter.
products = pd.read_csv(pyblp.data.NEVO_PRODUCTS_LOCATION)
agents = pd.read_csv(pyblp.data.NEVO_AGENTS_LOCATION)
print(f"Data: {products.market_ids.nunique()} markets, "
      f"{products.product_ids.nunique()} products, {len(products)} rows\n")

# The dependent variable in the logit model: ln(s_jt) - ln(s_0t)
outside_share = 1 - products.groupby("market_ids").shares.transform("sum")
y = np.log(products.shares) - np.log(outside_share)

# ---------------------------------------------------------------------------
# Step 1. Logit, no product fixed effects, price treated as exogenous
# ---------------------------------------------------------------------------
X = np.column_stack([np.ones(len(products)), products.prices, products.sugar, products.mushy])
ols_no_fe = np.linalg.lstsq(X, y, rcond=None)[0][1]

# ---------------------------------------------------------------------------
# Step 2. Add product fixed effects, which absorb a product's fixed quality
# ---------------------------------------------------------------------------
price_within = products.prices - products.groupby("product_ids").prices.transform("mean")
y_within = y - y.groupby(products.product_ids).transform("mean")
ols_fe = (price_within @ y_within) / (price_within @ price_within)

# ---------------------------------------------------------------------------
# Step 3. Add instruments for price (the instruments from the original paper).
# The first-stage R-squared shows how much of the within-product variation in
# price the 20 instrument columns explain.
# ---------------------------------------------------------------------------
logit_problem = pyblp.Problem(
    pyblp.Formulation("0 + prices", absorb="C(product_ids)"), products
)
logit = logit_problem.solve(method="2s")

instrument_columns = [c for c in products.columns if c.startswith("demand_instruments")]
Z = products[instrument_columns] - products.groupby("product_ids")[instrument_columns].transform("mean")
fitted = Z.to_numpy() @ np.linalg.lstsq(Z.to_numpy(), price_within, rcond=None)[0]
first_stage_r2 = 1 - ((price_within - fitted) ** 2).sum() / (price_within ** 2).sum()

# ---------------------------------------------------------------------------
# Step 4. Random coefficients: tastes vary with income, age, and children.
# Starting values are close to the solution. The gradient tolerance of 1e-5
# reproduces the "Tighter Tolerance" column of Table 7 in Conlon and Gortmaker.
# ---------------------------------------------------------------------------
rc_problem = pyblp.Problem(
    (
        pyblp.Formulation("0 + prices", absorb="C(product_ids)"),
        pyblp.Formulation("1 + prices + sugar + mushy"),
    ),
    products,
    pyblp.Formulation("0 + income + income_squared + age + child"),
    agents,
)
initial_sigma = np.diag([0.3302, 2.4526, 0.0163, 0.2441])
initial_pi = np.array([
    [ 5.4819,  0.0000,  0.2037,  0.0000],
    [15.8935, -1.2000,  0.0000,  2.6342],
    [-0.2506,  0.0000,  0.0511,  0.0000],
    [ 1.2650,  0.0000, -0.8091,  0.0000],
])
rc = rc_problem.solve(
    initial_sigma,
    initial_pi,
    optimization=pyblp.Optimization("bfgs", {"gtol": 1e-5}),
    method="1s",
)

print("Price coefficient (mean, for random coefficients)")
print(f"  Logit, OLS, no product effects:  {ols_no_fe:8.2f}")
print(f"  Logit, OLS, product effects:     {ols_fe:8.2f}")
print(f"  Logit, IV, product effects:      {logit.beta[0, 0]:8.2f}"
      f"  (first-stage R-squared {first_stage_r2:.2f})")
print(f"  Random-coefficients logit:       {rc.beta[0, 0]:8.2f}\n")

# ---------------------------------------------------------------------------
# Step 5. What the estimates imply for substitution.
# Element (j, k) of the elasticity matrix: percent change in the share of j when
# the price of k rises 1 percent.
# Element (j, k) of the diversion matrix: share of the sales j loses that go to
# k. The diagonal holds the share that goes to the outside good.
# ---------------------------------------------------------------------------
MARKET = "C01Q1"
EXAMPLE = "F1B13"
in_market = products[products.market_ids == MARKET].reset_index(drop=True)
example = in_market.index[in_market.product_ids == EXAMPLE][0]
sugary = (in_market.sugar >= 10).to_numpy()
rivals = np.arange(len(in_market)) != example


def rival_ratio(results):
    """When one price rises, how unequal are the responses of rival products?
    Largest rival cross-price elasticity divided by the smallest, median across
    products. A value of 1 means every rival responds in the same proportion."""
    E = results.compute_elasticities(market_id=MARKET)
    ratios = []
    for j in range(E.shape[1]):
        responses = np.delete(E[:, j], j)
        ratios.append(responses.max() / responses.min())
    return float(np.median(ratios))


s = in_market.shares[example]
p = in_market.prices[example]
print(f"Worked example: {EXAMPLE} in market {MARKET}, 14 grams of sugar")
print(f"  Share {s:.4f}, price {p:.4f}")
print(f"  Logit own-price elasticity by hand: {logit.beta[0, 0] * p * (1 - s):.2f}")
print(f"  Logit cross-price elasticity by hand: {-logit.beta[0, 0] * p * s:.3f}")
for name, results in [("Logit", logit), ("Random coefficients", rc)]:
    E = results.compute_elasticities(market_id=MARKET)
    D = 100 * results.compute_diversion_ratios(market_id=MARKET)[example]
    print(f"  {name}: own-price elasticity {E[example, example]:.2f}; lost sales go "
          f"{D[sugary & rivals].sum():.1f}% to sugary rivals, "
          f"{D[~sugary & rivals].sum():.1f}% to low-sugar rivals, "
          f"{D[example]:.1f}% to no purchase")
print()

# ---------------------------------------------------------------------------
# Step 6. Recover marginal costs from the firms' pricing equations.
# ---------------------------------------------------------------------------
old_prices = products.prices.to_numpy()
print("Marginal cost and margin (median across all rows)")
for name, results in [("Logit", logit), ("Random coefficients", rc)]:
    costs = results.compute_costs().flatten()
    print(f"  {name}: price {np.median(old_prices):.3f}, cost {np.median(costs):.3f}, "
          f"margin {100 * np.median((old_prices - costs) / old_prices):.1f}%")
print()

# ---------------------------------------------------------------------------
# Step 7. Simulate a merger of firms 1 and 2: the merged firm sets the prices of
# both firms' products, costs and demand stay fixed, and all firms choose new
# prices. Compare each model's predictions.
# ---------------------------------------------------------------------------
merged_firms = products.firm_ids.replace(2, 1).to_numpy()
merging = products.firm_ids.isin([1, 2]).to_numpy()

print(f"{'':48}{'Logit':>8}{'Random coef.':>14}")
rows = {}
for name, results in [("Logit", logit), ("RC", rc)]:
    own = results.extract_diagonals(results.compute_elasticities())
    new_prices = results.compute_prices(firm_ids=merged_firms, costs=results.compute_costs())
    change = new_prices.flatten() / old_prices - 1
    surplus_before = results.compute_consumer_surpluses()
    surplus_after = results.compute_consumer_surpluses(prices=new_prices)
    rows[name] = [
        np.median(own),
        rival_ratio(results),
        100 * np.median(change[merging]),
        100 * np.median(change[~merging]),
        100 * (surplus_after.mean() / surplus_before.mean() - 1),
    ]
labels = [
    "Median own-price elasticity",
    "Largest / smallest rival response",
    "Merger: median price change, merging firms (%)",
    "Merger: median price change, other firms (%)",
    "Merger: change in consumer surplus (%)",
]
for i, label in enumerate(labels):
    print(f"{label:48}{rows['Logit'][i]:8.2f}{rows['RC'][i]:12.2f}")
