#Ονοματεπώνυμο: Κυριακάκος Νικόλαος
#ΑΜ: 1115202200083

#Ονοματεπώνυμο: Παπαδόγιαννη Τριανταφυλλιά
#ΑΜ: 1115202200133

#Ονοματεπώνυμο: Κροκίδης Θεόδωρος
#ΑΜ: 1115202200081


#1
#Στο ερώτημα αυτό βρίσκουμε τους τίτλους των ταινιών στις οποίες έχει παίξει ο ηθοποιός με επώνυμο “Allen” και ανήκουν στο είδος “Comedy”.

SELECT DISTINCT m.title as Title
FROM movie m, role r, actor a, movie_has_genre mg, genre g
WHERE m.movie_id = r.movie_id
    AND r.actor_id = a.actor_id
    AND a.last_name = 'Allen'
    AND m.movie_id = mg.movie_id
    AND mg.genre_id = g.genre_id
    AND g.genre_name = 'Comedy';


#2
#Αρχικά, βρίσκουμε μέσω του εμφωλευμένου ερωτήματος τους σκηνοθέτες οι οποίοι έχουν σκηνοθετήσει τουλάχιστον 2 διαφορετικά είδη ταινιών.
#Έπειτα, με βάση αυτό στο κύριο μέρος βρίσκουμε τους τίτλους των ταινιών που έχουν σκηνοθετήσει και στις οποίες παίζει ηθοποιός με επώνυμο “Allen”.
#Τέλος, ταξινομούμε τα αποτελέσματα με αλφαβητική σειρά πρώτα κατ'όνομα σκηνοθέτη και έπειτα κατ'όνομα ταινίας.

SELECT d.last_name AS last_name, m.title AS title
FROM director d, movie_has_director md, movie m, role r, actor a
WHERE d.director_id = md.director_id
AND md.movie_id = m.movie_id
AND m.movie_id = r.movie_id
AND r.actor_id = a.actor_id
AND a.last_name = 'Allen'
AND d.director_id IN (
    SELECT md.director_id
    FROM movie_has_director md, movie m, movie_has_genre mg
    WHERE md.movie_id = m.movie_id
    AND m.movie_id = mg.movie_id
    GROUP BY md.director_id
    HAVING COUNT(DISTINCT mg.genre_id) >= 2
)
ORDER BY d.last_name, m.title;


#3
#Εδώ διατηρούμε πληροφορία για 2 σκηνοθέτες όπου ο ένας έχει ίδιο επώνυμο με τον ηθοποιό και ο άλλος διαφορετικό.
#Έπειτα, ελέγχουμε αν οι δύο ταινίες σκηνοθετήθηκαν από τους ίδιους σκηνοθέτες και αν έχουν τουλάχιστον ένα κοινό είδος.
#Αν η συνθήκη αυτή ισχύει, τότε εξαιρούμε τις περιπτώσεις όπου ο ηθοποιός έχει παίξει σε αυτές τις ταινίες.

SELECT DISTINCT a.last_name
FROM actor a, role r1, role r2, movie m1, movie m2, director d1, director d2,
     movie_has_director md1, movie_has_director md2
WHERE a.actor_id = r1.actor_id
    AND r1.movie_id = m1.movie_id
    AND m1.movie_id = md1.movie_id
    AND md1.director_id = d1.director_id
    AND d1.last_name = a.last_name
    AND a.actor_id = r2.actor_id
    AND r2.movie_id = m2.movie_id
    AND m2.movie_id = md2.movie_id
    AND md2.director_id = d2.director_id
    AND d2.last_name <> a.last_name
    AND EXISTS (
        SELECT *
        FROM movie m3, movie_has_genre mg1, movie_has_genre mg2
        WHERE m3.movie_id = mg1.movie_id
        AND m3.movie_id = mg2.movie_id
        AND mg1.genre_id = mg2.genre_id
        AND NOT EXISTS (
            SELECT *
            FROM role r3
            WHERE (r1.actor_id = r3.actor_id AND mg1.movie_id = r3.movie_id)
            OR (r2.actor_id = r3.actor_id AND mg2.movie_id = r3.movie_id)
        )
    );


#4
#Εδώ, με βάση τα υποερωτήματα, ελέγχουμε αν υπάρχει τουλάχιστον μία ταινία του 1995 του είδους "Drama".
#Αυτό το πετυχαίνουμε με χρήση υπαρξιακών τελεστών, οι οποίοι επιστρέφουν το αποτέλεσμα "yes" αν υπάρχει τέτοια ταινία και "no" αν δεν υπάρχει.
#Τα δύο σύνολα του UNION είναι ξένα μεταξύ τους, επομένως θα εμφανιστεί μόνο η μία απάντηση.
	
SELECT 'yes' AS answer
WHERE EXISTS
	(SELECT * FROM movie m, genre g, movie_has_genre mhg
              WHERE m.movie_id = mhg.movie_id
              AND g.genre_id = mhg.genre_id
              AND m.year = 1995
              AND g.genre_name = 'Drama')
UNION
SELECT 'no' AS Result
WHERE NOT EXISTS
	(SELECT * FROM movie m, genre g, movie_has_genre mhg
              WHERE m.movie_id = mhg.movie_id
              AND g.genre_id = mhg.genre_id
              AND m.year = 1995
              AND g.genre_name = 'Drama');


#5
#Εδώ, κινούμαστε με βάση τα id των σκηνοθετών ώστε να βρούμε τους δυνατούς τους συνδυασμούς, αποφεύγοντας έτσι κάποιος σκηνοθέτης να
#συνδυάζεται με τον εαυτό του ή με κάποιον άλλον 2 φορές (d1.director_id < d2.director_id). 
#Με βάση αυτό, για κάθε ζεύγος σκηνοθετών ελέγχουμε αν έχουν συνσκηνοθετήσει την ίδια ταινία
#στο δοσμένο χρονικό διάστημα και αν ο αριθμός των διαφορετικών ειδών που έχουν σκηνοθετήσει είναι τουλάχιστον 6.

SELECT DISTINCT
    d1.last_name AS director_1,
    d2.last_name AS director_2
FROM
    director d1, director d2, movie_has_director md1, movie_has_director md2,
    movie m1, movie m2, movie_has_genre mg1, movie_has_genre mg2
WHERE
    d1.director_id < d2.director_id
    AND d1.director_id = md1.director_id
    AND d2.director_id = md2.director_id
    AND md1.movie_id = m1.movie_id
    AND md2.movie_id = m2.movie_id
    AND m1.movie_id = mg1.movie_id
    AND m2.movie_id = mg2.movie_id
    AND m1.movie_id = m2.movie_id
    AND m1.year BETWEEN 2000 AND 2006
    AND m2.year BETWEEN 2000 AND 2006
GROUP BY
    d1.last_name, d2.last_name
HAVING
    COUNT(DISTINCT mg1.genre_id) >= 6
    AND COUNT(DISTINCT mg2.genre_id) >= 6;


#6
#Εδώ βρίσκουμε αρχικά τους ηθοποιούς που έχουν πάιξει σε ακριβώς 3 ταινίες και τους εμφανίζουμε ταξινομημένους με βάση το id.
#Επίσης, για κάθε έναν από αυτούς εμφανίζουμε και τον αριθμό των διαφορετικών σκηνοθετών που έχουν οι ταινίες του.

SELECT a.first_name as actor_name, a.last_name as actor_surname, COUNT(DISTINCT md.director_id) AS count
FROM actor a, role r, movie m, movie_has_director md
WHERE a.actor_id = r.actor_id
    AND r.movie_id = m.movie_id
    AND m.movie_id = md.movie_id
GROUP BY a.actor_id
HAVING COUNT(DISTINCT m.movie_id) = 3;


#7
#Στο συγκεκριμένο ερώτημα βρίσκουμε αρχικά μέσω του υποερωτήματος τις ταινίες που έχουν ένα μόνο είδος
#(δηλαδή αυτές για τις οποίες δεν υπάρχουν 2 διαφορετικά είδη).
#Με βάση το παραπάνω βρίσκουμε το είδος τους καθώς και τον αριθμό των σκηνοθετών του συγκεκριμένου είδους.

SELECT mhg.genre_id, COUNT(DISTINCT mhd.director_id) AS count
FROM movie_has_genre AS mhg, movie_has_director AS mhd
WHERE mhg.movie_id = mhd.movie_id
AND mhg.genre_id IN (
	SELECT DISTINCT genre_id
	FROM movie_has_genre AS mg1
	WHERE NOT EXISTS (
		SELECT *
		FROM movie_has_genre AS mg2
		WHERE mg1.movie_id = mg2.movie_id
		AND mg1.genre_id <> mg2.genre_id
	)
)
GROUP BY mhg.genre_id;


#8
#Στο συγκεκριμένο ερώτημα χρησιμοποιούμε ισοδύναμα διπλή άρνηση ως εξής:
#βρίσκουμε τους ηθοποιούς για τους οποίους δεν υπάρχει είδος για το οποίο
#να μην υπάρχει καμία ταινία στην οποία να έχουν παίξει.
#Συνεπώς, να μην υπάρχει κάποιο είδος στο οποίο να μην έχουν παίξει έστω και σε μία ταινία

SELECT DISTINCT r.actor_id
FROM role r
WHERE NOT EXISTS (
    SELECT *
    FROM genre g
    WHERE NOT EXISTS (
        SELECT *
        FROM movie_has_genre mg
        WHERE mg.genre_id = g.genre_id
        AND EXISTS (
            SELECT *
            FROM role r2
            WHERE r.actor_id = r2.actor_id
            AND mg.movie_id = r2.movie_id
        )
    )
);


#9
#Εδώ βρίσκουμε τους διαφορετικούς συνδυασμούς ειδών με βάση τα id για τα οποία υπάρχουν σκηνοθέτες που έχουν σκηνοθετήσει τουλάχιστον μια ταινία κάθε είδους
#και μετράμε τον αριθμό αυτό των σκηνοθετών.

SELECT
    g1.genre_id AS genre_id_1,
    g2.genre_id AS genre_id_2,
    COUNT(DISTINCT d.director_id) AS count
FROM
    director d, movie_has_director md1, movie_has_genre mg1, genre g1,
    movie_has_director md2, movie_has_genre mg2, genre g2
WHERE
    d.director_id = md1.director_id
    AND md1.movie_id = mg1.movie_id
    AND mg1.genre_id = g1.genre_id
    AND d.director_id = md2.director_id
    AND md2.movie_id = mg2.movie_id
    AND mg2.genre_id = g2.genre_id
    AND g1.genre_id < g2.genre_id
GROUP BY
    g1.genre_id, g2.genre_id;


#10
#Στο ερώτημα αυτό βρίσκουμε αρχικά τα είδη ταινιών που δεν έχουν σκηνοθέτη που έχει σκηνοθετήσει άλλες ταινίες με διαφορετικό είδος.
#Έπειτα, με βάση αυτό βρίσκουμε τους συνδυασμούς είδους-ηθοποιού και τον αριθμό των μοναδικών ταινιών όπου έχει παίξει ο ηθοποιός.

SELECT
    g.genre_id AS genre,
    a.actor_id AS actor,
    COUNT(DISTINCT m.movie_id) AS count
FROM
    actor a, role r, movie m, movie_has_genre mg, genre g
WHERE
    a.actor_id = r.actor_id
    AND r.movie_id = m.movie_id
    AND m.movie_id = mg.movie_id
    AND mg.genre_id = g.genre_id
    AND NOT EXISTS (
        SELECT *
        FROM
            movie_has_director md1, movie_has_genre mg1
        WHERE
            md1.movie_id = mg1.movie_id
            AND md1.director_id IN (
                SELECT md2.director_id
                FROM movie_has_director md2
                WHERE md2.movie_id = m.movie_id
            )
            AND mg1.genre_id <> g.genre_id
    )
GROUP BY
   g.genre_id, a.actor_id;