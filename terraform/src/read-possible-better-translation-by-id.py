import json, os
from neo4j import GraphDatabase, basic_auth

def lambda_handler(event,context):
    
    region = os.environ['AWS_REGION']
    password = os.environ['neo4j_password']
    user = os.environ['neo4j_user']
    
    endpoint = "neo4j+s://7abfe6cc.databases.neo4j.io"
    driver = GraphDatabase.driver(endpoint, auth=basic_auth(user, password))#PROD
    
    id_prop = event['id_prop']
    page =  event['page']
    
    id_prop = int(id_prop)
        
    params = {
        'id_prop': id_prop,
        'offset': 2,
        'page': page,
    }
    
    try:
        session = driver.session()
        
        cypher = """MATCH (bad:BadTranslation)-[:IMPROVED_BY]->(good:BetterTranslation)-[:PROPOSED_BY]->(u:User)
                    WHERE bad.id = $id_prop
                    WITH good, COUNT(u) as votes
                    RETURN *
                    ORDER BY votes DESC
                    SKIP $page*$offset
                    LIMIT $offset"""
        result = session.run(cypher, params)
        
        matched_possible_better_translations = list()
        for record in result:
            pb = dict(record["good"])
            pb.update({'votes': record['votes']})
            matched_possible_better_translations.append(pb)
        return json.dumps(matched_possible_better_translations)

    except Exception as e:
        driver.close()
        return str(e)

    finally:
        driver.close()