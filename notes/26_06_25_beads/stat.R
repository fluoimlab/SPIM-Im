
require(dplyr)
require(tidyr)
require(purrr)
require(rstatix)
require(ggplot2)
require(ggpubr)

setwd('~/bio_hardware/SPIM-Im/3_notes/26_06_25_beads/')

px.size <- 0.493  # um/px
px.zstep <- 0.625  # um/step

##### LATERAL #####
df <- rbind(read.csv('beads/lateral/01.csv') %>% mutate(bead = '01'),
            read.csv('beads/lateral/02.csv') %>% mutate(bead = '02'),
            read.csv('beads/lateral/03.csv') %>% mutate(bead = '03'),
            read.csv('beads/lateral/04.csv') %>% mutate(bead = '04'),
            read.csv('beads/lateral/05.csv') %>% mutate(bead = '05'),
            read.csv('beads/lateral/06.csv') %>% mutate(bead = '06')) %>%
      mutate(bead = as.factor(bead)) %>%
      group_by(bead) %>%
      mutate(norm = (Gray_Value-min(Gray_Value))/(max(Gray_Value)-min(Gray_Value)),
             idx = seq(1, length(Gray_Value)),
             rel_idx = idx - 8,
             rel_dist = rel_idx * px.size) %>%
      ungroup()

ggplot(data = df,
       aes(color = bead, x = rel_dist, y = norm)) +
  geom_line() +
  theme(legend.position = 'none')

##### AXIAL #####
df.ax <- rbind(read.csv('beads/axial/01.csv') %>% mutate(bead = '01'),
               read.csv('beads/axial/02.csv') %>% mutate(bead = '02'),
               read.csv('beads/axial/03.csv') %>% mutate(bead = '03'),
               read.csv('beads/axial/04.csv') %>% mutate(bead = '04'),
               read.csv('beads/axial/05.csv') %>% mutate(bead = '05'),
               read.csv('beads/axial/06.csv') %>% mutate(bead = '06')) %>%
  mutate(bead = as.factor(bead)) %>%
  group_by(bead) %>%
  mutate(norm = (Gray_Value-min(Gray_Value))/(max(Gray_Value)-min(Gray_Value)),
         idx = seq(1, length(Gray_Value)),
         rel_idx = idx - 12,
         rel_dist = rel_idx * px.zstep) %>%
  ungroup()

ggplot(data = df.ax,
       aes(color = bead, x = rel_idx, y = norm)) +
  geom_line() +
  scale_x_continuous(breaks = seq(-100,100)) +
  theme(legend.position = 'none')

##### GAUSSIAN FIT #####
fit.gaussian = function(x,y,mu,sig,scale){
  f = function(p){
    d = p[3]*dnorm(x,mean=p[1],sd=p[2])
    sum((d-y)^2)
  }
  optim(c(mu,sig,scale),f)
}

# lateral
df.median <- df %>%
  group_by(rel_idx) %>%
  mutate(norm_median = median(norm)) %>%
  ungroup() %>%
  select(rel_dist, norm_median) %>%
  distinct()

ggplot(data = df.median,
       aes(x = rel_dist, y = norm_median)) +
  geom_line() +
  theme(legend.position = 'none')

fit <- fit.gaussian(x = df.median$rel_dist, y = df.median$norm_median,
               mu = 0, sig = 2, scale = 1)

fit_x <- seq(-10,10, 0.1)
fit_val <- dnorm(fit_x,
                 mean = fit$par[1],
                 sd = fit$par[2]) * fit$par[3]
df.fit <- data.frame(x = fit_x, y = fit_val) %>%
  mutate(norm_val = (fit_val-min(fit_val))/(max(fit_val)-min(fit_val)))

fit$par
plot(fit_x, fit_val)

fwhm <- 2.355 * (fit$par[2])
fwhm

# axial
df.median.ax <- df.ax %>%
  group_by(rel_idx) %>%
  mutate(norm_median = median(norm)) %>%
  ungroup() %>%
  select(rel_dist, norm_median) %>%
  distinct()

ggplot(data = df.median.ax,
       aes(x = rel_dist, y = norm_median)) +
  geom_line() +
  theme(legend.position = 'none')

fit.ax <- fit.gaussian(x = df.median.ax$rel_dist, y = df.median.ax$norm_median,
                       mu = 0, sig = 2, scale = 1)

fit_ax_x <- seq(-20,20, 0.1)
fit_ax_val <- dnorm(fit_ax_x,
                    mean = fit.ax$par[1],
                    sd = fit.ax$par[2]) * fit.ax$par[3]
df.fit.ax <- data.frame(x = fit_ax_x, y = fit_ax_val) %>%
  mutate(ax_norm_val = (fit_ax_val-min(fit_ax_val))/(max(fit_ax_val)-min(fit_ax_val)))

fit.ax$par
plot(fit_ax_x, fit_ax_val)

fwhm.ax <- 2.355 * (fit.ax$par[2])
fwhm.ax

##### LATERAL FIT PLOT #####
ggplot(df, aes(x = rel_dist  - fit$par[1], y = norm)) +
  geom_hline(yintercept = 0.5, linetype = 2) +
  geom_vline(xintercept = fwhm/2, linetype = 2) +
  geom_vline(xintercept = -fwhm/2, linetype = 2) +
  geom_line(data = df.fit, aes(x = x - fit$par[1], y = norm_val), color = 'blue', size = 1.5) +
  geom_line(aes(group = bead), size = 0.25, color = 'grey30') +
  geom_point(aes(group = bead), size = 0.5, color = 'grey30') +
  scale_x_continuous(breaks = seq(-10, 10, 0.5),
                     limits = c(-3.5, 3.5)) +
  theme_minimal() +
  theme(legend.position = 'none') +
  labs(y = 'I norm.', x = 'Distance, µm',
       title = 'Lateral resolution',
       subtitle = 'Yellow-green beads 0.2 µm (n=6), 10x 0.25 NA, 0.493 µm/px \nExpected FWHM at 550 nm: ~1.12 µm \nEstimated FWHM: ~2.06 µm')

##### AXIAL FIT PLOT #####
ggplot(df.ax, aes(x = rel_dist  - fit$par[1], y = norm)) +
  # geom_vline(xintercept = 0.5, linetype = 2) +
  # geom_hline(yintercept = fwhm.ax/2, linetype = 2) +
  # geom_hline(yintercept = -fwhm.ax/2, linetype = 2) +
  geom_line(data = df.fit.ax, aes(x = x - fit.ax$par[1], y = ax_norm_val),
            color = 'blue', size = 1.5) +
  geom_line(aes(group = bead), size = 0.25, color = 'grey30') +
  geom_point(aes(group = bead), size = 0.5, color = 'grey30') +
  scale_x_continuous(breaks = seq(-10, 10, 1),
                     limits = c(-8, 8)) +
  theme_minimal() +
  theme(legend.position = 'none') +
  labs(y = 'I norm.', x = 'Distance, µm',
       title = 'Axial resolution',
       subtitle = 'Yellow-green beads 0.2 µm (n=6), 10x 0.25 NA, 0.625 µm/step \nExpected DoF at 550 nm: ~11.70 µm \nEstimated FWHM: ~6.32 µm')
