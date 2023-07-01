from neo4j import GraphDatabase, basic_auth

def lambda_handler(event,context):
    
    endpoint = 'neo4j://' + '10.0.146.95' + ':7687'
    driver = GraphDatabase.driver(endpoint, auth=basic_auth("neo4j", "password"), encrypted=False)#PROD
    
    fid = event['fid']
    second_id = event['secondid']
    from_text = event["from_text"]
    to_text = event["to_text"]
    addr = event["fingerprint"]
    
    params = {
        'fid': fid,
        'second_id': second_id,
        'from_text': from_text,
        'to_text': to_text,
        'addr': addr
    }
    
    try:
        session = driver.session()
        
        cypher = """CREATE CONSTRAINT BetterTranslationConstraint IF NOT EXISTS FOR (better:BetterTranslation) REQUIRE better.id IS UNIQUE"""
        session.run(cypher, params)
        
        cypher = """MERGE (:BetterTranslation {from_text: $from_text, to_text: $to_text, id: $second_id, fid: $fid})"""
        session.run(cypher, params)
        
        cypher = """MERGE (:User {ip: $addr})"""
        session.run(cypher, params)
        cypher = """ MATCH (u:User)
                    MATCH (better:BetterTranslation)
                    WHERE better.id = $second_id AND u.ip = $addr
                    MERGE (better)-[:PROPOSED_BY]->(u)
                """
        session.run(cypher, params)
        
        cypher = """ MATCH (bad:BadTranslation)
                    MATCH (better:BetterTranslation)
                    WHERE bad.id = better.fid
                    MERGE (bad)-[:IMPROVED_BY]->(better)
                    """
        session.run(cypher, params)
        return "all good"

    except Exception as e:
        driver.close()
        return str(e)

    finally:
        driver.close()
    