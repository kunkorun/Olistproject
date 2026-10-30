# 🇧🇷 Olist E-commerce Data Analysis

## 📌 Project Overview

This project focuses on analyzing the Brazilian e-commerce dataset provided by Olist.

The main goal is to explore sales performance, customer behavior, order delivery, and repeat purchases using **SQL and Python**.

The project combines database analysis in PostgreSQL with data exploration in Python to extract business insights from a large relational dataset.

## 🎯 Business Objectives

The analysis focuses on several key business questions:

- 📦 **Sales Analysis:** How do sales and orders change over time?
- 🚚 **Delivery Analysis:** How efficiently are orders delivered to customers?
- 👥 **Customer Behavior:** Do customers make repeat purchases?
- 🛍️ **E-commerce Performance:** What patterns can be identified in orders and customer activity?

## 📊 Dataset

The project uses the public **Brazilian E-Commerce Public Dataset by Olist**.

The dataset contains information about orders, customers, products, sellers, payments, reviews, and delivery.

**Dataset characteristics:**
- 9 relational tables
- More than 1.4 million records across the dataset
- Multiple entities connected through customer, order, product, seller, and geographic identifiers

## 🔍 Project Workflow

### 1. Data Preparation

- Imported the dataset into PostgreSQL.
- Explored the database structure and relationships between tables.
- Checked data quality and key fields.
- Investigated duplicate identifiers and potential issues that could affect JOIN results.

### 2. SQL Analysis

Used PostgreSQL to explore the data and answer business questions.

The analysis involved:

- `JOIN` — combining information from multiple tables.
- `CTE` — structuring complex queries.
- Subqueries — performing intermediate calculations.
- Window functions — analyzing records within groups and over time.
- Aggregate functions — calculating sales, order, and customer metrics.
- Date and time functions — examining temporal patterns.

### 3. Python Analysis

Used Python to work with query results and explore the data.

Main libraries:
- **Pandas** — data manipulation and analysis.
- **NumPy** — numerical operations.
- **Matplotlib / Seaborn** — data visualization.

### 4. Business Analysis

The project examines several aspects of e-commerce operations:

- Sales and order patterns.
- Order delivery performance.
- Customer purchasing behavior.
- Repeat purchases and customer activity.

## ⚠️ Data Quality Challenges

During the analysis, several issues required additional attention:

- Some identifiers were not unique, which could lead to duplicated rows after JOIN operations.
- The `review_id` field was not unique in all records.
- Geographic data contained repeated ZIP code prefixes, which could also affect JOIN results.
- The choice of join keys and table relationships was important for avoiding incorrect aggregations.

These issues highlighted the importance of checking data granularity and key uniqueness before calculating business metrics.

## 🛠️ Technologies

- **SQL:** PostgreSQL
- **Python:** Pandas, NumPy
- **Visualization:** Matplotlib, Seaborn
- **Environment:** Jupyter Notebook
- **Version Control:** Git, GitHub

## 💡 What I Learned

- Working with a multi-table relational database.
- Writing analytical SQL queries using JOINs, CTEs, subqueries, and window functions.
- Combining SQL and Python in an analytical workflow.
- Checking data quality and identifying problems with non-unique keys.
- Understanding how incorrect JOINs can lead to duplicated records and misleading metrics.
- Analyzing sales, delivery, and customer behavior in an e-commerce dataset.
- Translating business questions into analytical queries.

## 📚 Data Source

[ Brazilian E-Commerce Public Dataset by Olist — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

---

**Project:** [Olist E-commerce Data Analysis](https://github.com/kunkorun/Olistproject)