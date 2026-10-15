# 🛒 Olist E-Commerce — Analysis Summary

This is my practical SQL and data analysis project built around the Olist e-commerce dataset.

The main goal was to move beyond working with separate CSV files and learn how to turn related data into a structured PostgreSQL database, check its quality, and use SQL to investigate business questions. I also used Python and Matplotlib to visualize the results.

I focused on understanding the data and defining the metrics before interpreting the results. This is a learning project, so I documented the problems I found, the decisions I made, what went well, and what I would improve next time.

---

## 🎯 Goal

In this project I wanted to practice:

- exploring a multi-table dataset before starting the analysis;
- understanding grain, primary keys and foreign keys;
- designing a relational schema and creating tables in PostgreSQL;
- importing CSV files and validating the result;
- writing SQL queries to answer business questions;
- using Python and Matplotlib to visualize aggregated SQL results;
- interpreting findings carefully instead of treating every pattern as a proven explanation.

---

## 🗂️ Dataset & Structure

The project uses nine Olist CSV files: `customers`, `geolocation`, `order_items`, `order_payments`, `order_reviews`, `orders`, `products`, `sellers`, and `category_translation`.

I loaded the files into pandas first to understand their structure, then created a PostgreSQL database called `olist_analytics` and imported the data into nine related tables.

One important part of this stage was understanding what one row represents in each table. For example, one row in `orders` represents an order, while one row in `order_items` represents a product position within an order. This matters because joins and aggregations can produce incorrect results if the grain of each table is ignored.

---

## 🔍 Data Audit & Schema Design

Before writing the analysis queries, I checked table sizes, data types, missing values, full-row duplicates, key uniqueness and foreign-key relationships.

The key candidates I checked were:

- `customers`: `customer_id`
- `orders`: `order_id`
- `products`: `product_id`
- `sellers`: `seller_id`
- `order_items`: `(order_id, order_item_id)`
- `order_payments`: `(order_id, payment_sequential)`
- `order_reviews`: `(review_id, order_id)`
- `category_translation`: `product_category_name`

I initially expected `review_id` to be unique, but the data showed that it repeats. The combination of `review_id` and `order_id` was unique in my checks, so I used it as the composite primary key for `order_reviews`.

I also found that `customer_id` and `customer_unique_id` have different meanings. `customer_id` identifies a row in the customer table, while `customer_unique_id` is useful for grouping records by the same real customer in the repeat-purchase analysis.

In this dataset, each `customer_id` in `orders` was associated with at most one order, so the PostgreSQL design includes a `UNIQUE` constraint on `orders.customer_id`. This reflects the data I analysed, not a general rule for every e-commerce database.

### Data Quality Findings

- Several date fields in `orders` contain NULL values because not every order reached every delivery stage.
- Product category and product attribute fields contain missing values.
- Review title and review message fields contain many NULL values.
- `geolocation` contains 1,000,163 rows but only 19,015 unique ZIP prefixes. It also contains 261,831 repeated full-row occurrences.
- A ZIP prefix can point to multiple geolocation records. A direct join on ZIP prefix can multiply rows, so I did not treat that field as a unique key.
- Some products have no category or no corresponding English translation in `category_translation`.

The tested foreign-key relationships did not reveal missing parent keys. I kept the original missing values and repeated geolocation rows rather than automatically cleaning them without a defined analytical reason.

---

## 🛠️ PostgreSQL Setup & Import

I created the `olist_analytics` database in pgAdmin and created all nine tables with column types and key constraints.

I then imported the CSV files and compared the PostgreSQL row counts with the counts obtained during the pandas audit. During the import process, I ran into an issue with the CSV header setting: when `Header` was set incorrectly, PostgreSQL tried to import column names as data. This caused errors for numeric columns and added an extra row to two tables. I corrected the import settings and fixed the affected records.

After the import, I ran a post-import audit. The final checks matched the expected table sizes and verified key uniqueness, the tested foreign-key relationships, selected NULL counts, and other data-quality checks.

This stage taught me that a successful import message is not enough by itself. The imported data also needs to be validated.

---

## 📈 Business Analysis

I chose three business questions and used SQL to calculate the metrics before writing conclusions.

### 1. How does the value of sold products change over time?

**Metric:** monthly sum of `order_items.price` for orders with status `delivered`, grouped by the order purchase month.

This metric represents the value of product items in delivered orders. It excludes freight charges and should not be interpreted as total accounting revenue.

#### Key Findings

- The value of product items in delivered orders increased substantially from 2017 to 2018.
- October 2017 had a product-item value of `648,247.65`; in November 2017 it rose to `987,765.37` (**+52.37%**).
- Delivered orders increased from `4,478` to `7,289` over the same period (**+62.77%**).
- Average product-item value per delivered order decreased from `144.76` to `135.51` (**−6.39%**).
- The November 2017 spike was driven primarily by the increase in the number of delivered orders, rather than by a higher average product-item value per order.
- The last months of the dataset contain very few orders, so the sharp decline at the end of the chart is not evidence of a real collapse in sales.

The data show growth and monthly fluctuations, but I cannot confidently claim a recurring seasonal pattern from the limited period available.

### 2. How often are orders delivered later than promised?

**Metric:** the share of delivered orders whose actual delivery calendar date is later than the estimated delivery calendar date. Orders missing either date are excluded from the denominator.

#### Overall Result

- Delivered orders with both dates available: `96,470`
- Orders delivered late: `6,534`
- Orders delivered on time or earlier: `89,936`
- Overall late delivery rate: **6.77%**

I initially compared full timestamps and got a different result. I then changed the definition to compare calendar dates, which better matches the question of whether a delivery arrived later than the promised day. The consistent calendar-date definition produced the final rate of `6.77%`.

#### Monthly Findings

For orders placed from January 2017 through August 2018:

- The highest monthly late delivery rate was **18.96% in March 2018**.
- The lowest monthly late delivery rate was **1.16% in June 2018**.
- November 2017 and February–March 2018 also showed elevated late delivery rates.

Delivery performance varied considerably by order purchase month. The analysis identifies when the rate increased or decreased, but it does not establish the causes of these changes.

### 3. Is the rating of a customer's first order associated with a subsequent purchase?

**Metric:** the share of analysed customers who placed another order after the review date of their first chronological order.

I used `customer_unique_id` to group records by customer. If an order had multiple review rows, I calculated the average review score for that order. A subsequent purchase counted only if it was placed after the review date of the customer's first order.

| First-order rating group | Buyers in group | Buyers who repurchased | Repeat purchase rate |
|---|---:|---:|---:|
| Low (`< 3`) | 14,024 | 226 | 1.61% |
| Medium (`3` to `< 4`) | 7,875 | 141 | 1.79% |
| High (`4` to `5`) | 73,461 | 1,491 | 2.03% |

The observed repeat-purchase rate increased from `1.61%` in the low-rating group to `2.03%` in the high-rating group. This is a difference of **0.42 percentage points** and suggests a positive association within the analysed sample.

This analysis is limited to customers whose first chronological order had a recorded review. It does not prove that a higher rating causes a customer to purchase again. Other factors may be related to both customer ratings and later purchasing, and customers have different amounts of time in which to place a subsequent order.

The group comparison is included in this report and in the SQL analysis results. **I have not exported a separate repeat-purchase CSV file**, so this report does not link to one.

---

## 📎 Project Artifacts

The current project includes the following exported SQL result files:

- `outputs/monthly_olist_sales.csv` — monthly product-item value and order counts.
- `outputs/monthly_delivery_delays.csv` — monthly late-delivery rates and counts.

The ER diagram is saved separately:

- `diagrams/olist_er_diagram.png` — image for quick viewing.
- `diagrams/olist_er_diagram.drawio` — editable diagrams.net source.

The charts were generated in the Python notebook. They are not listed as standalone image files here because I have not confirmed separate PNG exports in the project folder.

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
- I found data-quality and modelling issues before relying on the data for analysis.
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

## 🧠 Final Reflection

The most useful part of this project so far has been learning to slow down before writing the analysis. Understanding the grain of each table, checking joins and defining metrics consistently helped me avoid misleading conclusions.

I am treating this as a practical learning project. The current findings are useful, but some questions need deeper analysis before I can make stronger claims. My next goal is to make the workflow cleaner and reproducible, so someone else can follow how the data was checked, how the metrics were calculated and how the conclusions were reached.
