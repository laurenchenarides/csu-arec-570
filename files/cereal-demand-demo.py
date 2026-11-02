# Cereal demand demo for AREC 570 / ECON 530, Lecture 6.2
#
# Estimates demand for ready-to-eat cereal in steps, then simulates a merger.
# The data are the simulated ("fake") data from Nevo (2000, Journal of Economics
# and Management Strategy), which ship with PyBLP (Conlon and Gortmaker 2020).
# Nevo writes that these data are "not real and should not be used for any
# analysis." Use them to learn the method, not to learn about cereal.
#
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

# The dependent variable in plain logit: ln(s_jt) - ln(s_0t)
outside_share = 1 - products.groupby("market_ids").shares.transform("sum")
y = np.log(products.shares) - np.log(outside_share)

# ---------------------------------------------------------------------------
# Step 1. Plain logit, no product fixed effects, price treated as exogenous
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
# Step 3. Add instruments for price (the instruments from the original paper)
# ---------------------------------------------------------------------------
logit_problem = pyblp.Problem(
    pyblp.Formulation("0 + prices", absorb="C(product_ids)"), products
)
logit = logit_problem.solve(method="2s")

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
print(f"  Plain logit, OLS, no product effects: {ols_no_fe:8.2f}")
print(f"  Plain logit, OLS, product effects:    {ols_fe:8.2f}")
print(f"  Plain logit, IV, product effects:     {logit.beta[0, 0]:8.2f}")
print(f"  Random coefficients:                  {rc.beta[0, 0]:8.2f}\n")


# ---------------------------------------------------------------------------
# Step 5. Compare what the two models say about substitution and a merger
# between firms 1 and 2. Compute "before" and "after" with each model.
# ---------------------------------------------------------------------------
def rival_ratio(results, market="C01Q1"):
    """When one price rises, how unequal are the responses of rival products?
    Largest rival cross-price elasticity divided by the smallest, median across
    products. A value of 1 means every rival responds in the same proportion."""
    E = results.compute_elasticities(market_id=market)
    ratios = []
    for j in range(E.shape[1]):
        rivals = np.delete(E[:, j], j)
        ratios.append(rivals.max() / rivals.min())
    return float(np.median(ratios))


merged_firms = products.firm_ids.replace(2, 1).to_numpy()
merging = products.firm_ids.isin([1, 2]).to_numpy()
old_prices = products.prices.to_numpy()

print(f"{'':44}{'Logit':>10}{'Random coef.':>14}")
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
