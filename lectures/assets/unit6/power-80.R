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

# Simulation: repeat the experiment many times with a true effect of -2
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
set.seed(5701)
cat(sprintf("Rejections in first 100 reps (n=253, -2): %d\n",
            round(100 * sim(253, -2, 100))))

# ---- Figure ----
green <- "#1e4d2b"; gray <- "#8a8a8a"; ink <- "#222222"; muted <- "#555555"
x  <- seq(-5, 3, length.out = 1200)
f0 <- dnorm(x, 0, se253)
f1 <- dnorm(x, -2, se253)
top <- max(f0)

if (grepl("\\.png$", out)) {
  png(out, width = 12, height = 5, units = "in", res = 200, type = "cairo", family = "Arial")
} else {
  svg(out, width = 12, height = 5, family = "Arial")
}
par(mar = c(4.4, 1, 0.5, 1), mgp = c(2.8, 0.8, 0), cex = 1.45)
plot(NA, xlim = c(-5, 3), ylim = c(0, top * 1.32), axes = FALSE,
     xlab = "Estimated difference in water use (acre-feet per farm-month)",
     ylab = "", col.lab = ink)

# Area under the "true effect = -2" curve where the test rejects: power
xr <- x[x <= -crit]
polygon(c(xr, rev(xr)), c(dnorm(xr, -2, se253), rep(0, length(xr))),
        col = adjustcolor(green, 0.30), border = NA)
# Areas under the "no effect" curve where the test rejects: Type I error
for (xt in list(x[x <= -crit], x[x >= crit])) {
  polygon(c(xt, rev(xt)), c(dnorm(xt, 0, se253), rep(0, length(xt))),
          col = adjustcolor(gray, 0.55), border = NA)
}

lines(x, f0, col = gray, lwd = 3)
lines(x, f1, col = green, lwd = 3)
segments(c(-crit, crit), 0, c(-crit, crit), top * 1.0, lty = 2, col = muted, lwd = 1.5)
text(c(-crit, crit), top * 1.0, sprintf(c("−%.2f", "%.2f"), crit),
     pos = 3, col = muted, cex = 0.8, offset = 0.3)
axis(1, at = -5:3, labels = sub("-", "−", -5:3), col = "#b5b5b5",
     col.axis = muted, lwd = 1.2)

text(-2.3, top * 1.24, "If the true effect is −2", col = ink, font = 2)
text(0.4, top * 1.24, "If there is no effect", col = ink, font = 2)
text(-5, top * 0.55, "80% of estimates\nfall below −1.39:\nthe test rejects", col = ink, cex = 0.9, adj = c(0, 0.5))
text(2.45, top * 0.30, "5% of estimates\nfall outside ±1.39\nwhen there is no\neffect (Type I error)", col = muted, cex = 0.8)
invisible(dev.off())
cat("Wrote", out, "\n")
