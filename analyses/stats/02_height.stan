data {
  int<lower=0> N;

  vector[N] height;
}
parameters {
  real mu;

  real<lower=0> sigma;
}
model {
  mu ~ normal(196, .75);

  sigma ~ exponential(1);

  height ~ normal(mu, sigma);
}
