from neo4j import GraphDatabase, basic_auth

def lambda_handler(event,context):
    endpoint = 'neo4j://' + '10.0.146.95' + ':7687'
    driver = GraphDatabase.driver(endpoint, auth=basic_auth("neo4j", "password"), encrypted=False)#PROD
    
    _from = event["from"]
    to = event["to"]
    from_text = event["from_text"]
    to_text = event["to_text"]
    _id = event["id"]
    addr = event["fingerprint"]
        
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
        
        cypher = """CREATE CONSTRAINT BadTranslationConstrain IF NOT EXISTS FOR (bad:BadTranslation) REQUIRE bad.id IS UNIQUE"""
        session.run(cypher, params)
        
        cypher = '''MERGE (b:BadTranslation { from_text: $from_text, from: $from, to: $to, to_text: $to_text, id: $id, addr: $addr})'''
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