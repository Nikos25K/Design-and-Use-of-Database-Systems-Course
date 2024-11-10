# # ----- CONFIGURE YOUR EDITOR TO USE 4 SPACES PER TAB ----- #
import sys,os
sys.path.append(os.path.join(os.path.split(os.path.abspath(__file__))[0], 'lib'))
import pymysql

def connection():
    ''' User this function to create your connections '''
    con = pymysql.connect(host='127.0.0.1', port=3306, user='root', passwd='1234', db='ergasia2') #update with your settings

    return con


# A function to cast and check if a value is negative or non-numeric
# and return the casted value or an error message
def is_negative(value, type):
    try:
        value = int(value) if type == 'int' else float(value)
        if value < 0:
            return "Error, negative number given"
        return value
    except ValueError:
        return "Error, non-numeric value given"

# A function to check the results of a query
def check_results(results):
    if len(results) == 0:
        return "No results found"
    else:
        return results

# A function that executes a query and returns the results
# or an error message if the query fails
def execute_query(cur, sql, args):
    try:
        cur.execute(sql, args)
        return check_results(cur.fetchall())
    except:
        return "Error, query failed"


def updateRank(rank1=None, rank2=None, movieTitle=None):
    if rank1 is None or rank2 is None or movieTitle is None:
        return [("status",),("error, not enough arguments",),]

    # #check if ranks are float numbers and movieTitle is a string
    rank1 = is_negative(rank1, 'float')
    rank2 = is_negative(rank2, 'float')
    if isinstance(rank1, str) or isinstance(rank2, str):
        return [("status",), (rank1 if isinstance(rank1, str) else rank2),]

    #check if movieTitle is a string
    if not isinstance(movieTitle, str):
        return [("status",),("error, movieTitle must be string",),]

    #check limits
    if rank1 > 10 or rank2 > 10:
        return [("status",),("error, rank must be less than 10",),]

    # Create a new connection
    con=connection()
    # Create a cursor on the connection
    cur=con.cursor()

    #run the query to get the movie
    sql = "SELECT * FROM movie WHERE title = %s"
    results = execute_query(cur, sql, (movieTitle,))

    #check that the query did not fail and results are correct
    if isinstance(results, str):
        return [("status",),(results,),]

    #get the rank of the movie
    rank = results[0][3]
    new_rank = (rank1 + rank2 + rank) / 3

    #update the rank of the movie
    sql = "UPDATE movie SET `rank` = %s WHERE title = %s"
    try:
        cur.execute(sql, (new_rank, movieTitle))
        con.commit()
    except:
        con.rollback()
        return [("status",),("error, update failed",),]


    con.close()
    return [("status",),("ok",),]


def colleaguesOfColleagues(actorId1=None, actorId2=None):
    if actorId1 is None or actorId2 is None:
        return [("status",),("error, not enough arguments",),]

    #check if they are integers and not negative
    actorId1 = is_negative(actorId1, 'int')
    actorId2 = is_negative(actorId2, 'int')
    if isinstance(actorId1, str) or isinstance(actorId2, str):
        return [("status",), (actorId1 if isinstance(actorId1, str) else actorId2 ,),]

    #check if not the same
    if actorId1 == actorId2:
        return [("status",),("error, actors are the same",),]

    # Create a new connection
    con=connection()

    # Create a cursor on the connection
    cur=con.cursor()

    #check if the actors exist
    sql = "select a.actor_id from actor a where a.actor_id = %s or a.actor_id = %s"

    results = execute_query(cur, sql, (actorId1, actorId2))
    if isinstance(results, str):
        return [("status",),(results,),]

    if(len(results) < 2):
        return [("status",),("error, actorId not found",),]

    #run the query to get the colleagues of the actors
    sql = """SELECT m1.title AS Movie_title, a3.actor_id AS Actor_c, a4.actor_id AS Actor_d
            FROM movie m1, role r1, role r2, actor a1, actor a2, actor a3, actor a4
            WHERE a1.actor_id = %s AND a2.actor_id = %s AND
            a3.actor_id = r1.actor_id AND m1.movie_id = r1.movie_id AND
            a4.actor_id = r2.actor_id AND m1.movie_id = r2.movie_id AND
                EXISTS (SELECT m2.movie_id
                        FROM movie m2, role r3, role r4
                        WHERE a1.actor_id = r3.actor_id AND m2.movie_id = r3.movie_id AND
                        a3.actor_id = r4.actor_id AND m2.movie_id = r4.movie_id) AND
                EXISTS (SELECT m3.movie_id
                        FROM movie m3, role r5, role r6
                        WHERE a2.actor_id = r5.actor_id AND m3.movie_id = r5.movie_id AND
                        a4.actor_id = r6.actor_id AND m3.movie_id = r6.movie_id);"""

    results = execute_query(cur, sql, (actorId1, actorId2))
    if isinstance(results, str):
        return [("status",),(results,),]

    formatted_results = [("movieTitle", "colleagueOfActor1", "colleagueOfActor2", "actor1","actor2",),]
    for (title, actor1, actor2) in results:
        formatted_results.append((title, actor1, actor2, actorId1, actorId2))

    return formatted_results


def actorPairs(actorId=None):
    if actorId is None:
        return [("status",),("error, not enough arguments",),]

    #check if actorId is an integer and not negative
    actorId = is_negative(actorId, 'int')
    if isinstance(actorId, str):
        return [("status",), (actorId),]

    # Create a new connection
    con=connection()

    # Create a cursor on the connection
    cur=con.cursor()

    #check if the actors exist
    sql = "select a.actor_id from actor a where a.actor_id = %s"

    results = execute_query(cur, sql, (actorId))
    if isinstance(results, str):
        return [("status",),(results,),]

    #run the query to get the actorPairs
    sql = """SELECT a1.actor_id
            FROM actor a1, actor a2, role r1, role r2, genre g1, movie_has_genre mg1
            WHERE a2.actor_id = %s AND a1.actor_id <> a2.actor_id AND
            	EXISTS (SELECT *
                        FROM movie m1
                        WHERE a1.actor_id = r1.actor_id AND m1.movie_id = r1.movie_id AND
                        g1.genre_id = mg1.genre_id AND m1.movie_id = mg1.movie_id AND
            		    a2.actor_id = r2.actor_id AND m1.movie_id = r2.movie_id) AND
                NOT EXISTS (SELECT m2.movie_id
                           FROM movie m2, genre g2, movie_has_genre mg2, role r3
                           WHERE a1.actor_id = r3.actor_id and m2.movie_id = r3.movie_id and
                           m2.movie_id = mg2.movie_id and g2.genre_id = mg2.genre_id and g1.genre_id <> g2.genre_id AND
                           NOT EXISTS (SELECT *
            						   FROM role r4
            						   WHERE r4.actor_id = r2.actor_id AND r4.movie_id = m2.movie_id)) AND
                NOT EXISTS (SELECT m3.movie_id
                           FROM movie m3, genre g3, movie_has_genre mg3, role r5
                           WHERE a2.actor_id = r5.actor_id and m3.movie_id = r5.movie_id and
                           m3.movie_id = mg3.movie_id and g3.genre_id = mg3.genre_id and g1.genre_id <> g3.genre_id AND
                           NOT EXISTS (SELECT *
            						   FROM role r6
            						   WHERE r6.actor_id = r1.actor_id AND r5.movie_id = m3.movie_id))
                group by a1.actor_id
                having count(distinct g1.genre_id) >= 7
                order by a1.actor_id;"""

    results = execute_query(cur, sql, (actorId))
    if isinstance(results, str):
        return [("status",),(results,),]

    formatted_results = [("actor",),]
    formatted_results.extend(results)

    return formatted_results

def selectTopNactors(n=None):
    if n is None:
        return [("status",),("error, not enough arguments",),]

    #check if n is an integer and not negative
    n = is_negative(n, 'int')
    if isinstance(n, str):
        return [("status",), (n),]

    # Create a new connection
    con=connection()
    # Create a cursor on the connection
    cur=con.cursor()

    #run the query to get the genres
    sql = "SELECT genre_id FROM genre"

    results = execute_query(cur, sql, ())
    if isinstance(results, str):
        return [("status",),(results,),]

    #initialize the list that will hold the results
    to_print = []

    #for each genre get all the actors and their movie count
    #and then we will keep the top n actors
    sql = """SELECT
            g.genre_name AS genre,
            a.actor_id AS actor,
            COUNT(DISTINCT m.movie_id) AS count
            FROM
                actor a, role r, movie m, movie_has_genre mg, genre g
            WHERE
                a.actor_id = r.actor_id
                AND r.movie_id = m.movie_id
                AND m.movie_id = mg.movie_id
                AND mg.genre_id = g.genre_id
                and g.genre_id = %s
            GROUP BY g.genre_id, a.actor_id
            ORDER BY count desc
            ;"""

    for(genre_id,) in results:

        new_results = execute_query(cur, sql, (genre_id,))
        # if there are no actors in the genre or the query failed continue
        if isinstance(new_results, str):
            continue

        count = 0
        #if there are less than n actors in the genre
        #will stop at the last actor
        for (genre, actor, movie_count) in new_results:
            if count < n:
                to_print.append((genre, actor, movie_count))
                count += 1
            else:
                break

    con.close()

    if to_print:
        # Format the output
        formatted_results = [("genre", "actor_id", "movie_count"),]
        formatted_results.extend(to_print)
        return formatted_results
    else:
        return [("status",), ("no actors found",),]


def findInfluencedActors(actorId, cur, sql, influencedActors):
    results = execute_query(cur, sql, (actorId,))
    #check if the query failed or there are no results
    if isinstance(results, str):
        return influencedActors

    for (row,) in results:
        if row not in influencedActors:
            influencedActors.append(row)
            influencedActors = findInfluencedActors(row, cur, sql, influencedActors)
    return influencedActors

def traceActorInfluence(actorId=None):
    if actorId is None:
        return [("status",),("error, not enough arguments",),]

    #check if actorId is an integer and not negative
    actorId = is_negative(actorId, 'int')
    if isinstance(actorId, str):
        return [("status",), (actorId),]

    # Create a new connection
    con=connection()

    # Create a cursor on the connection
    cur=con.cursor()

    #check if the actor exists
    sql = " select * from role r where r.actor_id = %s"

    results = execute_query(cur, sql, (actorId))
    if isinstance(results, str):
        return [("status",),(results,),]


    #run the query to get the actors that have been influenced by the actor
    sql = """SELECT DISTINCT r2.actor_id AS influencedActorId
            FROM role r1, movie_has_genre mg1, role r2, movie m1
            WHERE r1.movie_id = mg1.movie_id
            AND r2.movie_id = r1.movie_id
            AND m1.movie_id = mg1.movie_id
            AND r1.actor_id = %s
            AND r1.actor_id <> r2.actor_id
            AND EXISTS (
                SELECT 1
                FROM role r3, movie_has_genre mg2, movie m2
                WHERE r3.movie_id = mg2.movie_id
                AND r3.actor_id = r2.actor_id
                AND m2.movie_id = mg2.movie_id
                AND mg2.genre_id = mg1.genre_id
                AND m2.year > m1.year
            )
            ORDER BY r2.actor_id;"""

    results = execute_query(cur, sql, (actorId))
    if isinstance(results, str):
        return [("status",),(results,),]

    influencedActors = []
    for (influencedActorId,) in results:
        influencedActors.append(influencedActorId)
        influencedActors = findInfluencedActors(influencedActorId, cur, sql, influencedActors)

    influencedActors.sort()
    #delete duplicates
    for i in range(len(influencedActors)-1, 0, -1):
        if influencedActors[i] == influencedActors[i-1]:
            influencedActors.pop(i)

    formatted_results = [("influencedActorId",),]
    for actor in influencedActors:
        formatted_results.append((actor,))

    return formatted_results