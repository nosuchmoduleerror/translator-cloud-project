#!/bin/python3

import json, argparse, os
from neo4j import GraphDatabase
from neo4j.exceptions import ConstraintError


neo4j_port = 7687
limit = 2

'''query get all data from database'''
def getAll_db(driver, from_leng, to_leng, limit):
    
    try:
        with driver.session() as session:
            query = """
                        MATCH (bad:BadTranslation)-[:IMPROVED_BY]->(good:BetterTranslation)-[:PROPOSED_BY]->(u:User)
                        WHERE bad.from = $from_leng AND bad.to = $to_leng 
                        WITH good, bad, COUNT(u) as votes
                        RETURN *
                        ORDER BY votes DESC
                        LIMIT $limit
                    """
            result = session.execute_read(lambda tx, from_leng, to_leng, limit: tx.run(query, from_leng=from_leng, to_leng=to_leng, limit=limit).data(), from_leng, to_leng, limit)

    except ConstraintError as ce:
        print("ERROR: get all from database error")
    except Exception as e:
         print("ERROR")
    finally:
        driver.close()
        return result

'''query get all data from database'''   
def empty_db(driver):
    try:
        with driver.session() as session:
            query = """
                    MATCH (n) DETACH DELETE (n)
                    """
            result = session.execute_read(query)

    except ConstraintError as ce:
        print("ERROR: empty database error")
    except Exception as e:
         print("Empty database correct")
    finally:
        driver.close()
        return "{}"

#def train_model():

'''write data to files'''
def write_files(data):

    with open('./Data-Text_it-en/data_En_It-to.json', 'w') as f:
        for i in range(len(data)):
            f.write((data[i]["good"]["to_text"])+"\n")
        f.close()

    with open('./Data-Text_it-en/data_En_It-from.json', 'w') as f:
        for i in range(len(data)):
            f.write((data[i]["good"]["from_text"])+"\n")
        f.close()

    with open('./Data-Text_it-en/metadata.json', 'w') as f:
        metadata = {
                    "name": "cloud-translatorData",
                    "type": "data",
                    "from_code": "en",
                    "to_code": "it",
                    "reference": "Data from cloud-translator.com"
                    }
        f.write(json.dumps(metadata, indent=4, sort_keys=True, separators=(',', ': '), ensure_ascii=False))
        f.close()
    
def connection():
    parser = argparse.ArgumentParser(description='Script useful to get all and empty data from database')
    parser.add_argument("--address", "-ip", help="language to start with", required=True)
    parser.add_argument("--user", "-u", help="language in which I want to translate", default="neo4j")
    parser.add_argument("--password", "-p", help="text to test", default="password")
    args = parser.parse_args()

    return GraphDatabase.driver(f'neo4j://{args.address}:{neo4j_port}', auth=(args.user, args.password))

def main():
    '''suppose to be in a folder named "trainer" with inside the repository cloned argos-train'''
    driver = connection()
    data_En_It = getAll_db(driver, "en", "it", limit)
    data_It_En = getAll_db(driver, "it", "en", limit)
    #empty_db(driver)
    os.system("mkdir -p ./Data-Text_it-en")
    write_files(data_It_En)
    os.system("tar -zcvf ./Data-Text_it.argosdata ./Data-Text_it-en")

    os.system("./argos-train/bin/argos-train-init")


if __name__ == "__main__":
    main()