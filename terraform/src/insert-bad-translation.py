from neo4j import GraphDatabase, basic_auth
import socket
import os

def lambda_handler(event,context):
    
    region = os.environ['AWS_REGION']
    password = os.environ['neo4j_password']
    user = os.environ['neo4j_user']
    
    endpoint = "neo4j+s://7abfe6cc.databases.neo4j.io"
    driver = GraphDatabase.driver(endpoint, auth=basic_auth(user, password))#PROD
    
    _from = event["from"]
    to = event["to"]
    from_text = event["from_text"]
    to_text = event["to_text"]
    _id = event["id"]
    addr = event["fingerprint"]
    
    _id=int(_id)
    
    params = {
        'from': _from,
        'to': to,
        'from_text': from_text,
        'to_text': to_text,
        'id': _id,
        'addr': addr
    }
    
        
    try:
        session = driver.session()
        
        cypher = """MERGE (b:BadTranslation { from_text: $from_text, from: $from, to: $to, to_text: $to_text, id: $id, addr: $addr})"""
        session.run(cypher, params)
        
    except Exception as e:
        print (str(e), endpoint)
    
    try:
        cypher = """CREATE CONSTRAINT BadTranslationConstrain IF NOT EXISTS FOR (bad:BadTranslation) REQUIRE bad.id IS UNIQUE"""
        session.run(cypher, params)   
    
        cypher = """MERGE (:User {ip: $addr})"""
        session.run(cypher, params)

        cypher = """MATCH (u:User)
            MATCH (bad:BadTranslation)
            WHERE bad.id = $id AND u.ip=$addr
            MERGE (bad)-[:REPORTED_BY]->(u)
            """
        session.run(cypher, params)
        

    except Exception as e:
        driver.close()
        return str(e), endpoint

    finally:
        driver.close()