from neo4j import GraphDatabase, basic_auth
import os

def lambda_handler(event,context):
    
    region = os.environ['AWS_REGION']
    password = os.environ['neo4j_password']
    user = os.environ['neo4j_user']
    
    endpoint = "neo4j+s://7abfe6cc.databases.neo4j.io"
    driver = GraphDatabase.driver(endpoint, auth=basic_auth(user, password))#PROD
    
    page =  event["page"]
    
    params = {
        'page': page
    }
    
    try:
        session = driver.session()
        cypher = """ MATCH (b:BadTranslation)-[:REPORTED_BY]->(u:User)
                    WITH b, count(u) as complaints
                    RETURN *
                    ORDER BY complaints DESC
                    SKIP $page*10
                    LIMIT 10
                    """
        result = session.run(cypher, params)
        
        matched_bad_translations = list()
        for record in result:
            b = dict(record["b"])
            b.update({'complaints': record['complaints']})
            matched_bad_translations.append(b)
        return matched_bad_translations
        
    except Exception as e:
        driver.close()
        return str(e)
    finally:
        driver.close()
    