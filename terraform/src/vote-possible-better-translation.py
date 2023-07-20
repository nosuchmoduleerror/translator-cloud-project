from neo4j import GraphDatabase, basic_auth
import os

def lambda_handler(event,context):

    region = os.environ['AWS_REGION']
    password = os.environ['neo4j_password']
    user = os.environ['neo4j_user']
    
    endpoint = "neo4j+s://7abfe6cc.databases.neo4j.io"
    driver = GraphDatabase.driver(endpoint, auth=basic_auth(user, password))#PROD

    second_id = event['secondid']
    addr = event["fingerprint"]
    
    second_id=int(second_id)
        
    params = {
        'id': second_id,
        'ip': addr
    }
    
    
    try:
        with driver.session() as session:
            
            cypher = """MERGE (:User {ip: $ip})"""
            session.run(cypher, params)

            cypher = """MATCH (u:User)
                    MATCH (better:BetterTranslation)
                    WHERE better.id = $id AND u.ip = $ip
                    MERGE (better)-[:PROPOSED_BY]->(u)
                    RETURN *
                    """
            # a vote to a BetterTranslation is mapped with a PROPOSED_BY relation (link)
            session.run(cypher, params)
           

            cypher = """ MATCH (bad:BadTranslation)-[:IMPROVED_BY]->(good:BetterTranslation)-[:PROPOSED_BY]->(u:User)
                        WHERE good.id = $id
                        WITH good, COUNT(u) as votes, bad
                        RETURN votes, bad.id, good.id
                    """

            record = session.execute_read(cypher, params)
            data = json.dumps({"secondid": record[0]["good.id"], "fid": record[0]["bad.id"], "votes": record[0]["votes"]})
            
            return data
            
    except Exception as e:
        print('/vote_possible_better_translation: error in the execution of the query')
        print(e)
    finally:
        driver.close()
    
