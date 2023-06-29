# API Documentation

## Community
Here some notes about the `community.html` page:
*   suggesting an exsisting *bad* translation is equal to an **upvote** for that translation 
*   hash from_text and to_text in the better translation
*   suggesting an exsisting *better* translation *proposal* is equal to an **upvote** for that translation

<details>
<summary><strong>API</strong></summary>

## Translate API
### Query
```typescript
{
"from" : string, // source language
"to" : string, // target language
"from_text" : string, // text to be translated
"id" : int // request id
}
```

### Response
```typescript
{
"to_text" : string, // translated text
"id" : int // request id
}
```

## badTranslations write
```typescript
{
"from" : string, // source language
"to" : string, // target language
"from_text" : string, // text to be translated
"to_text" : string, // bad translation
"id" : int // request id
}
```

## badTranslations read (TODO: update for the **filter**)
### Query
```typescript
{
  "page" : int, //page number to be loaded
  "from" : string, // source language if we want to filter the results
  "to" : string // target language if we want to filter the results
}
```
### Response
```typescript
{
"from" : string, // source language
"to" : string, // target language
"from_text" : string, // text to be translated
"to_text" : string, // bad translation
"id" : int // request id
"complaints": int // number of complaints
}
```
## possibleBetterTranslations write
```typescript
{
  "from_text" : string, // text to be translated
  "to_text" : string, // proposed translation
  "secondid" : int, // request id
  "fid" : int // foreign key pointing at the bad translation
}
```

## possibleBetterTranslations read
```typescript
{
  "fid" : int, // foreign key pointing at the bad translation
  "page" : int // page number of the possible translations to be seen
}
```

## possibleBetterTranslations votes
```typescript
{
  "secondid" : int, // id of the possibleBetterTranslation
  "operation": int //+1 or -1 for a vote
}
```
</details>

<details>
<summary><strong>Virtual Enviroment set-up</strong></summary>

#### 1) Clone this repo
```
$ git clone https://github.com/aiman-al-masoud/translator-cloud-project.git
```
and navigate to its root directory.


#### 2) Create a python virtual environment
Use this name necessarily, because of the *.gitignore*
```
$ python3 -m venv .venv
```

(You'll be prompted to install the 'venv' module if you don't have it yet).


#### 3) Activate the virtual environment

```
$ source .venv/bin/activate
```

(You should notice that the console starts displaying the virtual environment's name before your username and the dollar-sign).

To exit from the virtual environment
```
$ deactivate
```

#### 4) Install this app's dependencies
Inside the virtual environment you just created:

```
(venv)$ pip install -r requirements.txt
```
</details>

<details>
<summary><strong>Get the models</strong> </summary>
Move to the *tests* directory and execute

```sh
python3 install-language-models.py -f en -t it -txt "Hello World"
# en -> it
```

```sh
python3 install-language-models.py -f it -t en -txt "Ciao Mondo"
# it -> en
```

If there are any problems with downloading language packages:
```
$ python3
>>> import argostranslate.package
>>> argostranslate.package.update_package_index()
>>> exit()
```

And then run the two commands above.
</details>

<details>
<summary><strong>MySQL set-up using Ubuntu</strong></summary>

#### 1) Update repositories
```sh
sudo apt update
```

#### 2) Install MySQL
```sh
sudo apt-get install mysql-server
```
and check if it is correctly installed
```sh
systemctl is-active mysql
```

#### 3) Set password
```sh
sudo mysql_secure_installation
# enter "2"
```

Use as password: `Cloud_08`
```sh
sudo mysql
```

```sh
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Cloud_08';
```

```sh
FLUSH PRIVILEGES;
```

```sh
exit
```

#### 4) Enter in mySQL
```sh
mysql -u root -p
```

```sh
systemctl status mysql.service
# check if the service is running
```

#### 5) Create database and tables
```sh
CREATE DATABASE `flask`;
```
```
use flask;
```
```sh
CREATE TABLE badTranslations (
FROMTAG varchar(2) not null,
TOTAG varchar(2) not null,
FROM_TEXT varchar(60) not null,
TO_TEXT varchar(60) not null,
ID integer(30) not null,
PRIMARY KEY (ID)
);
```

#### 6) Install the python library
```sh
pip install flask-mysqldb
```
For Linux/Unix platforms, before it, install
```sh
sudo apt install libmysqlclient-dev
```

### 7) Upgrade the database
Login to MySQL
```sh
mysql -u root -p
# pswd is "Cloud_08"
```
Set the using database
```
mysql> use flask;
```
Add the new column to the table **badTranslations**
```
mysql> ALTER TABLE badTranslations ADD COMPLAINTS integer(5) not null;
```
```
CREATE TABLE possibleBetterTranslations (
FROM_TEXT varchar(60) not null,
TO_TEXT varchar(60) not null,
SECONDID integer(30) not null,
FID integer(30) not null,
FOREIGN KEY (FID) REFERENCES badTranslations(ID),
PRIMARY KEY (SECONDID)
);
```
Add a new column to the table **possibleBetterTranslations**
```
mysql> ALTER TABLE possibleBetterTranslations ADD VOTES integer(5) not null;
mysql> ALTER TABLE possibleBetterTranslations ADD TIMESTAMP timestamp not null;
```

</details>

<details>
<summary><strong>MySQL set-up on Mac (M1)</strong></summary>

#### 1) Update repositories
```sh
brew update
```

```sh
brew upgrade
```

#### 2) Install MySQL
```sh
brew install mysql
```

#### 3) Set password
```sh
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Cloud_08';
```

```sh
FLUSH PRIVILEGES;
```

#### 4) Enter in mySQL
```sh
mysql -u root -p
```

#### 5) Create database and tables
```sh
CREATE DATABASE `flask`;
```
```
use flask;
```
```sh
CREATE TABLE badTranslations (
FROMTAG varchar(2) not null,
TOTAG varchar(2) not null,
FROM_TEXT varchar(60) not null,
TO_TEXT varchar(60) not null,
ID integer(30) not null,
PRIMARY KEY (ID)
);
```
</details>

<details>
<summary><strong>Neo4j set-up</strong></summary>
To run the db use the following command:

```sh
docker run --publish=7474:7474 --publish=7687:7687 --volume=$HOME/neo4j/data:/data neo4j
```

For other details see the dedicated documentation file (./scripts/docker-files/db)
</details>

That's it
