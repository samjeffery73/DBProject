/**
Sam Jeffery
Introduction to Databases Project, 2023

/** RESET PROCEDURES & TRIGGERS**/
DROP PROCEDURE IF EXISTS CreateNewUser;
DROP PROCEDURE IF EXISTS Subscribe;
DROP TRIGGER IF EXISTS DeleteSubAndPlaylists;
DROP TRIGGER IF EXISTS check_expiration;
DROP TRIGGER IF EXISTS update_end_date;


/** QUERIES **//
/** top 5 streams SONGS **/
SELECT project.name, project.genre, project.release_date, artists.name,
FORMAT(stream_number, 0) AS streams
FROM project
JOIN artists ON project.artist_id = artists.artist_id 
LEFT JOIN albums ON project.project_id = albums.album_id
WHERE albums.album_id IS NULL
ORDER BY stream_number DESC
LIMIT 5;

/** get how many times a user has listened to a song **/
SELECT
    c.username AS username,
    p.name as song_name,
    COUNT(l.listened_date) AS times_listened
FROM
    customer c
JOIN
    listen l ON c.user_id = l.listener_id
JOIN
    project p ON l.project_Id = p.project_id
GROUP BY
    c.username, p.name;

/** get 10 random songs**/
SELECT project.name, project.project_id
FROM project
INNER JOIN songs ON project.project_id = songs.song_id
ORDER BY RAND()
LIMIT 10;

/** Random shuffler for specific playlist **/
Select project.name, project.project_id
FROM project
INNER JOIN include ON project.project_id = include.projectid
WHERE playlist_id = 1
ORDER BY RAND()
LIMIT 1;

/** Lists all artists and their no. songs**/
SELECT artists.artist_id, artists.name, COUNT(project.project_id) AS song_count
FROM artists
JOIN project ON artists.artist_id = project.artist_id
JOIN songs ON project.project_id = songs.song_id
GROUP BY artists.artist_id, artists.name;


/** Query to get songs of a specific genre **/
SELECT songs.song_id, project.name, project.genre
FROM songs
INNER JOIN project ON songs.song_id = project.project_id
WHERE project.genre = 'hip-hop';

/** Get the name of songs and the album that they are contained on **/
SELECT songs.song_id,
       project_song.name AS song_name,
       project_album.name AS album_name
FROM songs
JOIN project AS project_song ON songs.song_id = project_song.project_id
LEFT JOIN albums ON songs.album_id = albums.album_id
LEFT JOIN project AS project_album ON albums.album_id = project_album.project_id;


/** Cont... Exclude songs that dont have an album **/
SELECT songs.song_id,
       project_song.name AS song_name,
       project_album.name AS album_name
FROM songs
JOIN project AS project_song ON songs.song_id = project_song.project_id
JOIN albums ON songs.album_id = albums.album_id
JOIN project AS project_album ON albums.album_id = project_album.project_id;



/** From featured artists, get their label.**/
SELECT artists.name AS featured_artist, artists.label AS featured_artist_label
FROM feature
JOIN artists ON feature.featured_id = artists.artist_id
JOIN project ON feature.project_id = project.project_id;



/*Get name, release date, and artist featured in a songs*/
SELECT feature.featured_id, artists.name, project.release_date, project.name
FROM feature
JOIN artists ON feature.featured_id = artists.artist_id
JOIN project ON feature.project_id = project.project_id;


/** CREATED INDEXES **/

CREATE INDEX username_idx
ON customer(username);

CREATE INDEX artist_idx
ON artists(name);

CREATE INDEX playlist_idx
ON playlist(name);

/** END INDEXES **/


/** STORED TRIGGERS **/
-- before deleting a user, delete all of their other possible data.
DELIMITER //
CREATE TRIGGER DeleteSubAndPlaylists
BEFORE DELETE
ON customer FOR EACH ROW
BEGIN
    -- Delete all customer data.
    DELETE FROM subscription WHERE subscriber_id = OLD.user_id LIMIT 1;
    DELETE FROM playlist WHERE creator_id = OLD.user_id LIMIT 1;
    DELETE FROM listen WHERE listener_id = OLD.user_id LIMIT 1;
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER Check_Expiration
BEFORE UPDATE ON subscription
FOR EACH ROW
BEGIN
    IF OLD.end_date <= CURRENT_DATE THEN
        SET NEW.subscription_type = 'free',
            NEW.subscription_Date = CURRENT_DATE,
            NEW.end_date = NULL;
    END IF;
END; //
DELIMITER ;


DELIMITER //
CREATE TRIGGER Update_End_Date
BEFORE UPDATE ON subscription
FOR EACH ROW
BEGIN
    IF NEW.subscription_type != 'free' THEN
        SET NEW.end_date = DATE_ADD(NEW.subscription_Date, INTERVAL 30 DAY);
    END IF;
END //
DELIMITER ;

/** END TRIGGERS **/

/** OPERATIONAL PROCEDURES **/

/** Create a new account for listening **/
DELIMITER //
CREATE PROCEDURE CreateNewUser(
    IN user_username VARCHAR(255),
    IN user_email VARCHAR(255),
    IN user_fname VARCHAR(255),
    IN user_lname VARCHAR(255),
    IN user_dob DATE,
    IN user_passwd VARCHAR(255)
)
BEGIN 
    -- insert into customer table
    INSERT INTO customer (username, email, first_name, last_name, `d.o.b`, password) 
    VALUES (user_username, user_email, user_fname, user_lname, user_dob, user_passwd);

   -- get incremented user id
    SET @last_user_id = last_insert_id();

    -- insert subscriber using user_id.
    INSERT INTO subscription (subscriber_id, subscription_type, subscription_date, price) 
    VALUES (@last_user_id, 'free', CURRENT_DATE, 0.00);
END //
DELIMITER ;


/** Update a subscription for a user **/
DELIMITER //
CREATE PROCEDURE Subscribe (

IN sub_payment_type VARCHAR(255),
IN user_username VARCHAR(255),
in subscription_type VARCHAR(255)
)

BEGIN
    DECLARE sub_price DECIMAL(10, 2);
    
    -- grab this customers id with matching username
    DECLARE existing_id INT;
    SELECT user_id INTO existing_id
    FROM customer
    WHERE username = user_username;
    -- determine what price their subscription is
    IF subscription_type = 'premium' THEN
        SET sub_price = 15.00;
    ELSEIF subscription_type = 'basic' THEN
        SET sub_price = 5.00;
    END IF;
	-- update subscription with matching id
    UPDATE subscription
    SET subscription_type = subscription_type,
        subscription_date = CURRENT_DATE,
        price = sub_price,
        payment_type = sub_payment_type
    WHERE subscriber_id = existing_id;artistsartists
END 

DELIMITER ;

/** END PROCEDURES **/

SELECT subscription.*, customer.username
FROM subscription
JOIN customer ON subscription.subscriber_id = customer.user_id;



/** exec **/
CALL CreateNewUser('billysue', 'test@test.com', 'billy', 'applebottom', '1999-09-10', 'password123');
CALL CreateNewUser('rdjrox', 'robertdowny@rdj.com', 'robert', 'downey', '1965-04-04', 'iamironman');
CALL Subscribe('credit card', 'freddyluvr', 'premium');




/** in case of AI errors in customer **/
alter table customer auto_increment = 9;




