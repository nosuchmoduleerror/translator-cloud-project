from neo4j import GraphDatabase, basic_auth

def lambda_handler(event,context):
    
    endpoint = 'neo4j://' + '10.0.146.95' + ':7687'
    driver = GraphDatabase.driver(endpoint, auth=basic_auth("neo4j", "password"), encrypted=False)#PROD
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
                    SKIP $page*2
                    LIMIT 2
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