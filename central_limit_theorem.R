# Central Limit Theorem Demonstration
# Shows that sample means approach a normal distribution regardless of
# the shape of the original population distribution.

set.seed(42)

# --- Parameters ---
n_simulations <- 10000          # number of samples drawn for each scenario
sample_sizes  <- c(1, 5, 30, 100)  # sample sizes to compare
pop_size      <- 1e6            # large population to draw from

# --- Population: right-skewed exponential (mean = 1, sd = 1) ---
population <- rexp(pop_size, rate = 1)
pop_mean   <- mean(population)
pop_sd     <- sd(population)

cat(sprintf("Population shape : Exponential(rate=1)\n"))
cat(sprintf("Population mean  : %.4f\n", pop_mean))
cat(sprintf("Population SD    : %.4f\n\n", pop_sd))

# --- Simulate sample means for each sample size ---
simulate_sample_means <- function(pop, n, reps) {
  replicate(reps, mean(sample(pop, size = n, replace = TRUE)))
}

sample_means_list <- lapply(sample_sizes, simulate_sample_means,
                            pop = population, reps = n_simulations)
names(sample_means_list) <- paste0("n=", sample_sizes)

# --- Plot ---
png("central_limit_theorem.png", width = 900, height = 1100, res = 110)

# Layout: population spans full top row; 4 sample-size panels below in 2x2
layout(matrix(c(1, 1, 2, 3, 4, 5), nrow = 3, byrow = TRUE),
       heights = c(1, 1, 1))
old_par <- par(mar = c(4, 4, 3, 1), oma = c(0, 0, 3, 0))

# Panel 1: population distribution (truncated for readability)
pop_sample <- sample(population, 50000)
hist(pop_sample,
     breaks  = 80,
     freq    = FALSE,
     col     = "darkorange",
     border  = "white",
     xlim    = c(0, 8),
     main    = "Population Distribution  (Exponential, rate=1)",
     xlab    = "Value",
     ylab    = "Density")
x_seq <- seq(0, 8, length.out = 300)
lines(x_seq, dexp(x_seq, rate = 1), col = "firebrick", lwd = 2)
legend("topright",
       legend = sprintf("True density\nmu=%.2f, sd=%.2f", pop_mean, pop_sd),
       col    = "firebrick", lwd = 2, bty = "n", cex = 0.8)

# Panels 2-5: sampling distributions for each n
for (i in seq_along(sample_sizes)) {
  n      <- sample_sizes[i]
  means  <- sample_means_list[[i]]
  clt_mean <- pop_mean
  clt_sd   <- pop_sd / sqrt(n)

  hist(means,
       breaks  = 60,
       freq    = FALSE,
       col     = "steelblue",
       border  = "white",
       main    = sprintf("Sample size n = %d", n),
       xlab    = "Sample mean",
       ylab    = "Density")

  x_seq <- seq(min(means), max(means), length.out = 300)
  lines(x_seq, dnorm(x_seq, mean = clt_mean, sd = clt_sd),
        col = "firebrick", lwd = 2)

  legend("topright",
         legend = sprintf("CLT normal\nmu=%.2f, sd=%.3f", clt_mean, clt_sd),
         col    = "firebrick", lwd = 2, bty = "n", cex = 0.8)
}

mtext("Central Limit Theorem  —  Exponential Population",
      outer = TRUE, cex = 1.2, font = 2)

par(old_par)
dev.off()
cat("Plot saved to central_limit_theorem.png\n")

# --- Numerical check: compare empirical vs CLT predictions ---
cat("n        emp_mean  clt_mean  emp_sd    clt_sd\n")
cat(strrep("-", 52), "\n")
for (i in seq_along(sample_sizes)) {
  n     <- sample_sizes[i]
  means <- sample_means_list[[i]]
  cat(sprintf("%-8d %.4f    %.4f    %.4f    %.4f\n",
              n,
              mean(means), pop_mean,
              sd(means),   pop_sd / sqrt(n)))
}

# --- Shapiro-Wilk normality test on 5 000 of the simulated means ---
cat("\nShapiro-Wilk p-value (closer to 1 => more normal):\n")
for (i in seq_along(sample_sizes)) {
  n     <- sample_sizes[i]
  means <- sample_means_list[[i]]
  sw    <- shapiro.test(sample(means, 5000))
  cat(sprintf("  n = %3d : W = %.4f,  p = %.4f\n", n, sw$statistic, sw$p.value))
}
