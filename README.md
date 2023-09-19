# business-analysis-sql-tableau

## Table of Contents

1. [Introduction](#introduction)
2. [Dataset](#dataset)
3. [Data Schema](#Dataschema)
4. [Graphs in Tableau](#graphsintableau)
5. [Files in this repository](#filesinthisrepository)

### Introduction
E-commerce company on the potential merger 

Eniac is exploring an expansion to the Brazilian market. The company doesn't have experience in this market or ties with local providers, package delivery services, or customer service agencies. 
The eCommerce company is researching whether to merge with Magist, which is a Brazilian Software as a Service company that offers a centralized order management system to connect small and medium-sized stores with the biggest Brazilian marketplaces. 

Magist is already a big player and allows small companies to benefit from its economies of scale: it has signed advantageous contracts with the marketplaces and with the Post Office, thus reducing the cost of fees and, most importantly, the bureaucracy involved to get things started.

The two main concerns are:
Eniac's catalog is 100% tech products, and heavily based on Apple-compatible accessories. It is not clear that the marketplaces Magist's works with are a good place for these high-end tech products.
Among Eniac’s efforts to have happy customers, fast deliveries are key. The delivery fees resulting from Magist's deal with the public Post Office might be cheap, but at what cost? Are deliveries fast enough? 

The goal is to answer the following questions:
  1. Is the brazilian online marketplace "Magist" a good fit for high-end tech products, especially for Apple-compatible accessories?
  2. Are deliveries fast enough?

In relation to the products:

  1. Which categories of tech products does Magist have?
  2. How many products of these tech categories have been sold (within the time window of the database snapshot)? What percentage does that represent from the overall number of products sold?
  3. What’s the average price of the products being sold?
  4. Are expensive tech products popular?

In relation to the sellers:

  1. How many months of data are included in the magist database?
  2. How many sellers are there? How many Tech sellers are there? What percentage of overall sellers are Tech sellers?
  3. What is the total amount earned by all sellers? What is the total amount earned by all Tech sellers?
  4. Can you work out the average monthly income of all sellers? Can you work out the average monthly income of Tech sellers?

In relation to the delivery time:

  1. What’s the average time between the order being placed and the product being delivered?
  2. How many orders are delivered on time vs orders delivered with a delay?
  3. Is there any pattern for delayed orders, e.g. big products being delayed more often?

### Dataset
The dataset is made available by Kaggle and has been provided by Olist, the largest department store in Brazilian marketplaces. For purposes of this example Olist will be refered as Magist.
Magits connects small businesses from all over Brazil to channels without hassle and with a single contract. 
Those merchants are able to sell their products through the Magist Store and ship them directly to the customers using Magist logistics partners. 
The dataset has information of 100k orders from 2016 to 2018 made at multiple marketplaces in Brazil.
Its features allows viewing an order from multiple dimensions: from order status, price, payment and freight performance to customer location, product attributes and finally reviews written by customers. We also released a geolocation dataset that relates Brazilian zip codes to lat/lng coordinates.

### Database Schema
![Magist Database schema](https://github.com/lauraborel/business-analysis-sql-tableau/blob/main/EER_Magist.png)

Basic Description of Tables and their Relations
Let’s focus first of all on some tables that are just collections of items, independent of any transaction.

Unless a new customer makes a purchase, a new product is released, or a new seller is registered, these tables remain unchanged during a transaction:

* products: contains a row for each product available for sale.
* product_category_name_translation: contains a relation of product categories in its original language, Portuguese, and English.
* sellers: contains a row for each one of the sellers registered in the marketplace.
* customers:  contains a row for each customer that has made a purchase.
* geo: contains a relation between zip codes, coordinates, and states, to obtain more precise information about sellers and customers.

The following tables are the ones responsible for capturing a purchase:
* orders: every time that an order is placed, a row is inserted in this table. Even if the order contains multiple products, here it will be reflected as a single row with an order_id that uniquely identifies it.
* order_items: this table contains one row for each distinct product of an order.

After an order is placed, a customer still needs to pay for it, then they can write a review. This information is stored in the corresponding tables:

* order_payments: customers can pay an order with different methods of payment. Every time a payment is made a row is inserted here. An order can be paid in installments, which means that a single order can have many separate payments.
* order_reviews: customers can leave multiple reviews corresponding to the order they placed.

### Graphs in Tableau:
* Cross Monthly Customer Spend
* Customers Location
* Share of Tech Products
* Top N Sellers

### Files in this repository
* Dump file for setting up the database
* SQL queries:explore dataset
* SQL queries:answer specific business questions
* 5 minute presentation on answering main business challenge
* folder with csv files for all tables
* folder with additional data and SQL scrip file for intermediate level SQL challenges
Note: Downloaded the data with the code of Brazilian States here: https://github.com/datasets-br/state-codes and imported the CSV file with "Table data import wizard from CSV"
