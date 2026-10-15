# 🛒 Olist E-Commerce — SQL & Data Analysis

This is my practical SQL and data analysis project built around the Olist e-commerce dataset.

I wanted to move beyond working with separate CSV files and learn how to turn related data into a PostgreSQL database, check its quality, and use SQL to investigate business questions. I also used Python and Matplotlib to visualize the results.

I tried to follow the same approach throughout the project: understand the data first, define a metric, run a query, check the result, and only then write down a conclusion.

---

## 🎯 Goal

In this project I wanted to practice:

- exploring a multi-table dataset before starting the analysis;
- understanding table grain, primary keys and foreign keys;
- designing a relational schema and creating tables in PostgreSQL;
- importing CSV files and validating the result;
- writing SQL queries to answer business questions;
- using Python and Matplotlib to visualize aggregated SQL results;
- understanding how joins can multiply rows and lead to misleading metrics;
- documenting what I learned, including mistakes and limitations.

---

## 🗂️ Dataset

I used the [Brazilian E-Commerce Public Dataset by Olist on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). It contains e-commerce orders from 2016–2018 and supporting information about customers, products, sellers, payments, reviews and geolocation.

The project uses these nine CSV files:

- `olist_customers_dataset.csv`
- `olist_geolocation_dataset.csv`
- `olist_orders_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_order_payments_dataset.csv`
- `olist_order_reviews_dataset.csv`
- `olist_products_dataset.csv`
- `olist_sellers_dataset.csv`
- `product_category_name_translation.csv`

The original dataset is not included in this repository. Download it from the source above and follow the dataset's license terms.

---

## 🔍 Data Audit & Schema Design

Before writing analytical queries, I loaded the CSV files with pandas and checked table sizes, data types, missing values, duplicate rows, candidate keys and relationships between tables.

I then created the `olist_analytics` database in PostgreSQL and represented the nine tables in an ER diagram.

### Table sizes

| Table | Rows |
|---|---:|
| `customers` | 99,441 |
| `geolocation` | 1,000,163 |
| `orders` | 99,441 |
| `order_items` | 112,650 |
| `order_payments` | 103,886 |
| `order_reviews` | 99,224 |
| `products` | 32,951 |
| `sellers` | 3,095 |
| `category_translation` | 71 |

### Key findings

- `customer_id` and `customer_unique_id` have different meanings. `customer_id` identifies a record in the customer table, while `customer_unique_id` is useful for grouping orders by the same real customer.
- `order_items` uses the composite key `(order_id, order_item_id)`.
- `order_payments` uses `(order_id, payment_sequential)` as a composite key.
- `review_id` was not unique in this dataset. The combination `(review_id, order_id)` was unique in my checks.
- `geolocation_zip_code_prefix` is not unique. Joining `geolocation` directly by ZIP prefix can multiply rows, so I did not treat it as a primary key.
- Some order dates, product attributes and review comments contain missing values.
- Some products have no category or no matching English translation in `category_translation`.

I also checked the foreign-key relationships used in the schema. The tested joins did not reveal missing parent keys. I kept the original missing values and repeated geolocation rows rather than cleaning them without a specific analytical reason.

### ER Diagram

I created the diagram to understand how the tables fit together before writing the analytical queries.

![Olist ER diagram](diagrams/olist_er_diagram.png)

Editable diagrams.net source: [olist_er_diagram.drawio](diagrams/olist_er_diagram.drawio)

---

## 🛠️ PostgreSQL Setup & Import

I created the `olist_analytics` database in pgAdmin and created all nine tables with column types and key constraints. I then imported the CSV files and compared the PostgreSQL row counts with the counts from the initial pandas audit.

During the import process, I ran into an issue caused by the CSV header setting. When `Header` was set incorrectly, PostgreSQL tried to import column names as data. This produced type errors and added an extra row to two tables. I corrected the import settings and checked the row counts again.

After importing the files, I ran a post-import audit to check row counts, key uniqueness, selected NULL counts, header rows, category translation coverage and the tested foreign-key relationships.

This was a useful reminder that a successful import message is not enough by itself. The imported data also needs to be validated.

---

## 📈 Business Analysis

I chose three business questions and used SQL to calculate the metrics before interpreting the results.

### 1. How does the value of sold products change over time?

**Metric:** monthly sum of `order_items.price` for orders with status `delivered`, grouped by the month of `order_purchase_timestamp`.

This represents the value of product items in delivered orders. It excludes freight charges and should not be interpreted as total accounting revenue.

**What I found:**

- Product-item value in delivered orders increased substantially between 2017 and 2018.
- From October to November 2017, the value increased from `648,247.65` to `987,765.37` (**+52.37%**).
- Delivered orders increased from `4,478` to `7,289` over the same period (**+62.77%**).
- Average product-item value per delivered order decreased from `144.76` to `135.51` (**−6.39%**).
- The November 2017 spike was driven mainly by the larger number of delivered orders, not by a higher average product-item value per order.
- The last months of the dataset contain very few orders, so the sharp drop at the end of the chart is not evidence of a real collapse in sales.

I found growth and monthly fluctuations, but I cannot confidently claim a recurring seasonal pattern from the limited period available.

### 2. How often are orders delivered later than promised?

**Metric:** the share of delivered orders whose actual delivery calendar date was later than the estimated delivery calendar date. Orders missing either date are excluded from the denominator.

**Overall result:**

- Delivered orders with both dates available: `96,470`
- Orders delivered late: `6,534`
- Orders delivered on time or earlier: `89,936`
- Overall late delivery rate: **6.77%**

I initially compared full timestamps and got a different result. I then changed the definition to compare calendar dates, which better matches the question of whether a delivery arrived later than the promised day.

**Monthly results:**

- Highest late-delivery rate in the analysed period: **18.96% in March 2018**.
- Lowest late-delivery rate: **1.16% in June 2018**.
- November 2017 and February–March 2018 also showed elevated late-delivery rates.

The results show that delivery performance varied by month, but they do not explain why those changes happened.

### 3. Is the rating of a customer's first order associated with a subsequent purchase?

**Metric:** the share of analysed customers who placed another order after the review date associated with their first chronological order.

I used `customer_unique_id` to group records by customer. If an order had multiple review rows, I calculated the average review score for that order. A subsequent purchase counted only if it was placed after the review date of the customer's first order.

| First-order rating group | Buyers in group | Buyers who repurchased | Repeat purchase rate |
|---|---:|---:|---:|
| Low (`< 3`) | 14,024 | 226 | 1.61% |
| Medium (`3` to `< 4`) | 7,875 | 141 | 1.79% |
| High (`4` to `5`) | 73,461 | 1,491 | 2.03% |

The observed repeat-purchase rate increased from `1.61%` in the low-rating group to `2.03%` in the high-rating group, a difference of **0.42 percentage points**.

This suggests a positive association in the analysed sample, but it does not prove that a higher rating causes a customer to purchase again. The analysis includes only customers whose first order had a review, and customers have different amounts of time in which to place a subsequent order.

The repeat-purchase result is documented in this table and in the SQL analysis. I have **not** exported it as a separate CSV file.

### Visualizations

The sales and delivery charts were generated in the Python notebook. In this version, I have not linked separate PNG exports for these charts, so the README does not point to image files that may not be present in the repository.

---

## 💡 What I Learned

This project helped me understand several things more clearly:

- **Grain matters.** Before joining tables, I need to know what one row represents. `orders` and `order_items` do not have the same grain.
- **A join key is not always a unique key.** `geolocation_zip_code_prefix` can be used to connect data, but it is not unique in `geolocation`; a direct join can multiply rows.
- **Composite keys are useful.** Some tables are identified by a combination of columns rather than a single ID.
- **SQL results need validation.** I checked row counts, keys, missing values and joins rather than assuming the import had worked correctly.
- **Metric definitions matter.** Comparing timestamps gave a different late-delivery rate than comparing calendar dates. I had to make the definition consistent before using the result.
- **`COUNT(DISTINCT ...)` and `SUM(...)` answer different questions.** A single order may contain several item rows, so counting rows is not the same as counting orders.
- **A graph shows a pattern, not its cause.** The November 2017 sales spike became more meaningful after I compared item value, order count and average item value per order.
- **Association is not causation.** The repeat-purchase analysis shows a relationship between rating groups and repeat-purchase rate, but it does not prove that ratings cause customers to buy again.

I also got more practice with PostgreSQL features such as `DATE_TRUNC`, CTEs, aggregate `FILTER`, window functions (`LAG` and `ROW_NUMBER`), `COUNT(DISTINCT ...)`, `PERCENTILE_CONT` and joins across related tables.

---

## ✅ What Went Well

- I completed a data audit before starting the business analysis.
- I designed and created a PostgreSQL schema for nine related tables.
- I imported the CSV files and validated the results against the original pandas row counts.
- I caught and corrected import problems caused by the CSV header setting.
- I found several data-quality and modelling issues before relying on the data for analysis.
- I used SQL to calculate metrics and Python/Matplotlib to visualize them.
- I revisited a metric when I noticed that the definition based on timestamps was inconsistent with the business question.
- I documented limitations instead of claiming that every observed pattern had a known cause.

---

## 🚧 What I Would Improve

If I continue this project, I would:

- make the analysis queries more modular and keep one final version of each query;
- make the Python notebook and exported outputs easier to reproduce;
- investigate the November 2017 sales spike and the February–March 2018 delivery-delay peaks in more detail;
- analyse delivery delays by geography, seller or product category, while avoiding row multiplication from the geolocation table;
- make the repeat-purchase analysis more robust by considering customer observation windows and other potential confounding factors;
- decide how to handle geolocation duplicates and missing product categories based on a clear analytical use case;
- add a BI dashboard after the SQL analysis is stable.

---

## 📁 Project Structure

The structure below shows the intended layout. If a local filename is different, the paths in this README should be updated to match the repository.

```text
project_brazilian/
├── README.md
├── analysis_summary.md
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_post_import_audit.sql
│   └── 03_business_analysis.sql
├── notebooks/
│   └── olist_analysis.ipynb
├── outputs/
│   ├── monthly_olist_sales.csv
│   └── monthly_delivery_delays.csv
├── diagrams/
│   ├── olist_er_diagram.drawio
│   └── olist_er_diagram.png
└── data/  (download locally; original CSV files are not committed)
```

There is no separate `repeat_purchase_by_rating.csv` in the current version. The repeat-purchase result is included in this README and the detailed report instead.

---

## ▶️ How to Run

1. Download the [Olist dataset from Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and place the CSV files locally.
2. Create a PostgreSQL database named `olist_analytics`.
3. Run the table-creation script in `sql/` against a new, empty database.
4. Import the CSV files using pgAdmin or another CSV import tool. Make sure the CSV `Header` option is set to `Yes`.
5. Run the post-import audit script and check the row counts and key relationships.
6. Execute the business-analysis queries. The monthly sales and delivery query results are exported to the `outputs/` folder; the repeat-purchase result is documented in the SQL output and the report, not in a separate CSV.
7. Open the Python notebook to review the visualization and analysis steps.

The table-creation script is intended for a new, empty database and should not be rerun against an already populated database without understanding the consequences.

---

## 📌 Current Status

Completed:

- data audit and initial schema design;
- PostgreSQL table creation and CSV import;
- post-import validation;
- three exploratory business questions with SQL analysis;
- initial Python visualizations and written interpretations.

Still to improve:

- final organisation of the notebook and exported outputs;
- reproducibility and documentation;
- deeper analysis of the observed sales and delivery patterns;
- a BI dashboard.

---

## 🧠 Final Reflection

The most useful part of this project so far has been learning not to jump straight into analysis. I had to understand the grain of each table, check the relationships, fix import problems and define the metrics carefully before interpreting the results.

I am treating this as a practical learning project. The current findings are useful, but some questions need deeper analysis before I can make stronger claims. My next goal is to make the workflow cleaner and reproducible, so someone else can follow how I checked the data, calculated the metrics and reached the conclusions.
