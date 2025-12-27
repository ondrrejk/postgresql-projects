/* I'll be making the tables:
1. authors
2. books
3. members
4. loans
each with their specific columns.
*/
CREATE TABLE authors (
    author_id SERIAL NOT NULL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    birth_year INT
)

CREATE TABLE books (
    book_id SERIAL NOT NULL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    published_year YEAR,
    author_id INT REFERENCES authors(author_id)
)

CREATE TABLE members (
    member_id SERIAL NOT NULL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    joined_date DATE DEFAULT CURRENT_DATE
)

CREATE TABLE loans (

)