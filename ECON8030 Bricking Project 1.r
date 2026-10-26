install.packages("readxl")  # Run once if needed
library(readxl)

data <- read_excel("P_Data_Extract_From_World_Development_Indicators (1).xlsx")

install.packages("dplyr")  # Run once if needed
install.packages("tidyr")  # Run once if needed
install.packages("readr")  # Run once if needed
library(dplyr)
library(tidyr)
library(readr)

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2")
}
library(ggplot2)

year_columns <- names(data)[grepl("^\\d{4}", names(data))]
available_years <- sort(as.integer(substr(year_columns, 1, 4)))
growth_period_years <- tail(available_years, 15)

gdp_pc_growth <- data |>
  filter(`Series Name` == "GDP per capita (constant 2015 US$)") |>
  pivot_longer(
    cols = matches("^\\d{4}"),
    names_to = "year",
    values_to = "gdp_per_capita"
  ) |>
  mutate(
    year = as.integer(substr(year, 1, 4)),
    gdp_per_capita = parse_number(as.character(gdp_per_capita))
  ) |>
  arrange(`Country Name`, year) |>
  group_by(`Country Name`) |>
  mutate(
    growth_rate_pct = 100 * (gdp_per_capita / lag(gdp_per_capita) - 1)
  ) |>
  ungroup() |>
  filter(year %in% growth_period_years)

growth_table <- gdp_pc_growth |>
  select(`Country Name`, year, growth_rate_pct) |>
  mutate(growth_rate_pct = round(growth_rate_pct, 2)) |>
  arrange(`Country Name`, year) |>
  pivot_wider(
    names_from = year,
    values_from = growth_rate_pct,
    names_prefix = "year_"
  )

View(growth_table)

write.csv(
  growth_table,
  file = "gdp_per_capita_growth_rates.csv",
  row.names = FALSE
)

install.packages("ggplot2")
library(ggplot2)

growth_plot <- ggplot(
  filter(gdp_pc_growth, !is.na(growth_rate_pct)),
  aes(
    x = year,
    y = growth_rate_pct,
    color = `Country Name`,
    group = `Country Name`
  )
) +
  geom_hline(yintercept = 0, color = "gray60", linewidth = 0.5) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = growth_period_years) +
  labs(
    title = "GDP per capita growth trajectories",
    x = "Year",
    y = "Annual growth rate (%)",
    color = "Country"
  ) +
  theme_minimal()

print(growth_plot)

ggsave(
  filename = "gdp_per_capita_growth_trajectories.png",
  plot = growth_plot,
  width = 10,
  height = 6,
  dpi = 300
)

data2 <- read_excel("Project 1 Part 3.xlsx")

project1_part3_gdp_growth <- data2 |>
  filter(`Series Name` == "GDP per capita (constant 2015 US$)") |>
  pivot_longer(
    cols = matches("^[0-9]{4}"),
    names_to = "year",
    values_to = "gdp_per_capita",
    values_transform = list(gdp_per_capita = as.character)
  ) |>
  mutate(
    year = as.integer(substr(year, 1, 4)),
    gdp_per_capita = parse_number(gdp_per_capita, na = c("", ".."))
  ) |>
  arrange(`Country Name`, year) |>
  group_by(`Country Name`) |>
  mutate(
    growth_rate_pct = 100 * (gdp_per_capita / lag(gdp_per_capita) - 1),
    period = case_when(
      year < 1990 ~ "Pre-1990",
      year >= 1990 & year <= 2007 ~ "1990-2007",
      year >= 2008 ~ "2008 onward"
    )
  ) |>
  ungroup() |>
  filter(!is.na(period), !is.na(growth_rate_pct))

project1_part3_group_summary <- project1_part3_gdp_growth |>
  group_by(period) |>
  summarise(
    average_gdp_growth_pct = mean(growth_rate_pct, na.rm = TRUE),
    years_with_growth_rate = n(),
    .groups = "drop"
  )

View(project1_part3_group_summary)

data3 <- read_excel("Project 1 Part 4.xlsx")

gdp_series <- "GDP per capita (constant 2015 US$)"
comparison_variables <- c(
  "Unemployment, total (% of total labor force) (modeled ILO estimate)",
  "Control of Corruption - Governance score (0-100)",
  "Foreign direct investment, net outflows (% of GDP)",
  "Population growth (annual %)"
)

project1_part4_long <- data3 |>
  pivot_longer(
    cols = matches("^\\d{4}$"),
    names_to = "year",
    values_to = "value",
    values_transform = list(value = as.character)
  ) |>
  mutate(
    year = as.integer(year),
    value = parse_number(value, na = c("", ".."))
  ) |>
  pivot_wider(
    names_from = `Series Name`,
    values_from = value
  ) |>
  mutate(gdp_per_capita = .data[[gdp_series]]) |>
  pivot_longer(
    cols = all_of(comparison_variables),
    names_to = "comparison_variable",
    values_to = "comparison_value"
  ) |>
  filter(!is.na(gdp_per_capita), !is.na(comparison_value)) |>
  arrange(`Country Name`, comparison_variable, year)

for (variable in comparison_variables) {
  comparison_plot <- project1_part4_long |>
    filter(comparison_variable == variable) |>
    ggplot(
      aes(
        x = gdp_per_capita,
        y = comparison_value,
        color = `Country Name`,
        group = `Country Name`
      )
    ) +
    geom_path(alpha = 0.6, na.rm = TRUE) +
    geom_point(size = 1.8, na.rm = TRUE) +
    scale_color_viridis_d(name = "Country", option = "turbo") +
    labs(
      title = paste("GDP per capita and", variable),
      subtitle = "Countries share one graph; lines connect each country's observations over time",
      x = "GDP per capita (constant 2015 US$)",
      y = variable
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(face = "bold"),
      legend.position = "right"
    )

  print(comparison_plot)

  file_stub <- gsub("[^a-z0-9]+", "_", tolower(variable))
  ggsave(
    filename = paste0("project1_part4_gdp_per_capita_vs_", file_stub, ".png"),
    plot = comparison_plot,
    width = 12,
    height = 8,
    dpi = 300
  )
}

project1_part4_country_averages <- project1_part4_long |>
  group_by(year, comparison_variable) |>
  summarise(
    average_gdp_per_capita = mean(gdp_per_capita),
    average_comparison_value = mean(comparison_value),
    countries_in_average = n_distinct(`Country Name`),
    .groups = "drop"
  )

for (variable in comparison_variables) {
  average_plot <- project1_part4_country_averages |>
    filter(comparison_variable == variable) |>
    ggplot(
      aes(
        x = average_gdp_per_capita,
        y = average_comparison_value,
        color = year,
        group = 1
      )
    ) +
    geom_path(linewidth = 0.8, na.rm = TRUE) +
    geom_point(size = 2.2, na.rm = TRUE) +
    scale_color_viridis_c(name = "Year") +
    labs(
      title = paste("Average GDP per capita and", variable),
      subtitle = "Each point is the average across countries with valid values for both indicators in that year",
      x = "Average GDP per capita (constant 2015 US$)",
      y = paste("Average", variable)
    ) +
    theme_minimal() +
    theme(plot.title = element_text(face = "bold"))

  print(average_plot)

  file_stub <- gsub("[^a-z0-9]+", "_", tolower(variable))
  ggsave(
    filename = paste0(
      "project1_part4_average_gdp_per_capita_vs_",
      file_stub,
      ".png"
    ),
    plot = average_plot,
    width = 10,
    height = 7,
    dpi = 300
  )
}

project1_part4_annual_averages <- data3 |>
  pivot_longer(
    cols = matches("^\\d{4}$"),
    names_to = "year",
    values_to = "value",
    values_transform = list(value = as.character)
  ) |>
  mutate(
    year = as.integer(year),
    value = parse_number(value, na = c("", ".."))
  ) |>
  pivot_wider(
    names_from = `Series Name`,
    values_from = value
  ) |>
  group_by(year) |>
  summarise(
    across(
      all_of(c(gdp_series, comparison_variables)),
      ~ if (all(is.na(.x))) NA_real_ else mean(.x, na.rm = TRUE)
    ),
    .groups = "drop"
  )

correlation_variables <- c(gdp_series, comparison_variables)
project1_part4_correlation_matrix <- cor(
  select(project1_part4_annual_averages, all_of(correlation_variables)),
  use = "pairwise.complete.obs"
)

print(round(project1_part4_correlation_matrix, 3))
write.csv(
  project1_part4_correlation_matrix,
  file = "project1_part4_average_country_correlation_matrix.csv"
)

project1_part4_correlation_plot_data <- as.data.frame(
  as.table(project1_part4_correlation_matrix)
) |>
  rename(
    variable_x = Var1,
    variable_y = Var2,
    correlation = Freq
  ) |>
  mutate(
    variable_x = factor(variable_x, levels = correlation_variables),
    variable_y = factor(variable_y, levels = rev(correlation_variables))
  )

correlation_plot <- ggplot(
  project1_part4_correlation_plot_data,
  aes(x = variable_x, y = variable_y, fill = correlation)
) +
  geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%.2f", correlation)), size = 3.5) +
  scale_fill_gradient2(
    low = "#B2182B",
    mid = "white",
    high = "#2166AC",
    midpoint = 0,
    limits = c(-1, 1),
    name = "Correlation"
  ) +
  scale_x_discrete(labels = \(x) stringr::str_wrap(x, width = 22)) +
  scale_y_discrete(labels = \(x) stringr::str_wrap(x, width = 22)) +
  coord_equal() +
  labs(
    title = "Correlation Matrix of Annual Country Averages",
    subtitle = "Correlations are calculated across years using pairwise complete observations",
    x = NULL,
    y = NULL
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 35, hjust = 1),
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(correlation_plot)
ggsave(
  filename = "project1_part4_average_country_correlation_matrix.png",
  plot = correlation_plot,
  width = 12,
  height = 10,
  dpi = 300
)

project1_part4_country_year_values <- data3 |>
  pivot_longer(
    cols = matches("^\\d{4}$"),
    names_to = "year",
    values_to = "value",
    values_transform = list(value = as.character)
  ) |>
  mutate(
    year = as.integer(year),
    value = parse_number(value, na = c("", ".."))
  ) |>
  pivot_wider(
    names_from = `Series Name`,
    values_from = value
  ) |>
  arrange(`Country Name`, year) |>
  group_by(`Country Name`) |>
  mutate(
    previous_year = lag(year),
    gdp_per_capita_growth_pct = if_else(
      year - previous_year == 1,
      100 * (.data[[gdp_series]] / lag(.data[[gdp_series]]) - 1),
      NA_real_
    )
  ) |>
  ungroup()

project1_part4_annual_growth_averages <- project1_part4_country_year_values |>
  group_by(year) |>
  summarise(
    average_gdp_per_capita_growth_pct = if (
      all(is.na(gdp_per_capita_growth_pct))
    ) {
      NA_real_
    } else {
      mean(gdp_per_capita_growth_pct, na.rm = TRUE)
    },
    .groups = "drop"
  )

project1_part4_growth_correlation_data <- project1_part4_annual_averages |>
  select(year, all_of(comparison_variables)) |>
  left_join(project1_part4_annual_growth_averages, by = "year")

growth_correlation_variables <- c(
  "average_gdp_per_capita_growth_pct",
  comparison_variables
)
project1_part4_growth_correlation_matrix <- cor(
  select(project1_part4_growth_correlation_data, all_of(growth_correlation_variables)),
  use = "pairwise.complete.obs"
)
rownames(project1_part4_growth_correlation_matrix)[1] <-
  "Average GDP per capita growth (annual %)"
colnames(project1_part4_growth_correlation_matrix)[1] <-
  "Average GDP per capita growth (annual %)"

print(round(project1_part4_growth_correlation_matrix, 3))
write.csv(
  project1_part4_growth_correlation_matrix,
  file = "project1_part4_average_country_growth_correlation_matrix.csv"
)

growth_correlation_plot_data <- as.data.frame(
  as.table(project1_part4_growth_correlation_matrix)
) |>
  rename(
    variable_x = Var1,
    variable_y = Var2,
    correlation = Freq
  ) |>
  mutate(
    variable_x = factor(
      variable_x,
      levels = colnames(project1_part4_growth_correlation_matrix)
    ),
    variable_y = factor(
      variable_y,
      levels = rev(rownames(project1_part4_growth_correlation_matrix))
    )
  )

growth_correlation_plot <- ggplot(
  growth_correlation_plot_data,
  aes(x = variable_x, y = variable_y, fill = correlation)
) +
  geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%.2f", correlation)), size = 3.5) +
  scale_fill_gradient2(
    low = "#B2182B",
    mid = "white",
    high = "#2166AC",
    midpoint = 0,
    limits = c(-1, 1),
    name = "Correlation"
  ) +
  scale_x_discrete(labels = \(x) stringr::str_wrap(x, width = 22)) +
  scale_y_discrete(labels = \(x) stringr::str_wrap(x, width = 22)) +
  coord_equal() +
  labs(
    title = "Correlation Matrix of Annual Country Averages",
    subtitle = "GDP per capita growth is averaged across countries by year; correlations use pairwise complete years",
    x = NULL,
    y = NULL
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 35, hjust = 1),
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(growth_correlation_plot)
ggsave(
  filename = "project1_part4_average_country_growth_correlation_matrix.png",
  plot = growth_correlation_plot,
  width = 12,
  height = 10,
  dpi = 300
)
