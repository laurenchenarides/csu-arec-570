# Power figure for Lecture 6.4 (water-use report example)
# Usage: Rscript power-80.R <output.png|output.svg>
args <- commandArgs(trailingOnly = TRUE)
out <- args[1]

# ---- Numbers used in the slides ----
se253 <- 8 * sqrt(2 / 253)
crit  <- qnorm(0.975) * se253
cat(sprintf("SE(253)=%.3f  crit=%.3f  power(normal)=%.3f\n",
            se253, crit, pnorm((2 - crit) / se253)))
se51 <- 8 * sqrt(2 / 51)
cat(sprintf("SE(51)=%.3f  crit=%.3f  power(normal)=%.3f\n",
            se51, qnorm(0.975) * se51, pnorm((2 - qnorm(0.975) * se51) / se51)))
for (d in c(1, 3)) {
  cat(sprintf("n=253, effect=%d: power(normal)=%.3f\n", d, pnorm((d - crit) / se253)))
}

# Simulation: repeat the experiment many times
set.seed(570)
sim <- function(n, effect, reps = 10000) {
  mean(replicate(reps, {
    y0 <- rnorm(n, 0, 8); y1 <- rnorm(n, effect, 8)
    t.test(y1, y0, var.equal = TRUE)$p.value < 0.05
  }))
}
cat(sprintf("Sim reject rate, n=253, effect=-2: %.3f\n", sim(253, -2)))
cat(sprintf("Sim reject rate, n=253, effect= 0: %.3f\n", sim(253, 0)))
cat(sprintf("Sim reject rate, n=51,  effect=-2: %.3f\n", sim(51, -2)))

# ---- Figure ----
green <- "#1e4d2b"; gray <- "#8a8a8a"; ink <- "#222222"; muted <- "#555555"
x  <- seq(-5, 3, length.out = 1200)
f0 <- dnorm(x, 0, se253)
f1 <- dnorm(x, -2, se253)
top <- max(f0)

if (grepl("\\.png$", out)) {
  png(out, width = 12, height = 5.6, units = "in", res = 200, type = "cairo", family = "Arial")
} else {
  svg(out, width = 12, height = 5.6, family = "Arial")
}
par(mar = c(4.4, 1, 0.3, 1), mgp = c(2.8, 0.8, 0), cex = 1.45)
plot(NA, xlim = c(-5, 3), ylim = c(0, top * 1.72), axes = FALSE,
     xlab = "Estimated difference in water use (acre-feet per farm-month)",
     ylab = "", col.lab = ink)

poly <- function(xx, m, ...) {
  polygon(c(xx, rev(xx)), c(dnorm(xx, m, se253), rep(0, length(xx))), ...)
}
# Power: "true effect = -2" curve beyond the cutoff
poly(x[x <= -crit], -2, col = adjustcolor(green, 0.30), border = NA)
# Beta: "true effect = -2" curve inside the cutoffs (hatched)
poly(x[x > -crit & x < crit], -2, col = green, border = NA, density = 14, angle = 45, lwd = 1)
# Alpha: "no effect" curve beyond the cutoffs
poly(x[x <= -crit], 0, col = adjustcolor(gray, 0.60), border = NA)
poly(x[x >= crit], 0, col = adjustcolor(gray, 0.60), border = NA)

lines(x, f0, col = gray, lwd = 3)
lines(x, f1, col = green, lwd = 3)
segments(c(-crit, crit), 0, c(-crit, crit), top * 1.0, lty = 2, col = muted, lwd = 1.5)
text(c(-crit, crit), top * 1.0, sprintf(c("−%.2f", "%.2f"), crit),
     pos = 3, col = muted, cex = 0.8, offset = 0.3)
axis(1, at = -5:3, labels = sub("-", "−", -5:3), col = "#b5b5b5",
     col.axis = muted, lwd = 1.2)

# Curve labels
text(-2.3, top * 1.2, "If the true effect is −2", col = ink, font = 2)
text(0.4, top * 1.2, "If there is no effect", col = ink, font = 2)

# Distance between the centers = true effect
arrows(-2, top * 1.36, 0, top * 1.36, code = 3, angle = 90, length = 0.06, col = muted, lwd = 1.5)
text(-1, top * 1.36, "Distance between centers = true effect (2 acre-feet)",
     pos = 3, col = ink, cex = 0.85, offset = 0.35)

# Legend for the shaded areas
legend(-5.1, top * 1.75, horiz = TRUE, bty = "n", cex = 0.85, text.col = ink,
       x.intersp = 0.5, text.width = c(1.9, 2.6, 2.6),
       legend = c("Power = 0.80",
                  "β = 0.20 (effect missed)",
                  "α = 0.05 (false positive)"),
       fill = c(adjustcolor(green, 0.30), green, adjustcolor(gray, 0.60)),
       density = c(NA, 30, NA), angle = 45,
       border = c(NA, green, NA))
invisible(dev.off())
cat("Wrote", out, "\n")
