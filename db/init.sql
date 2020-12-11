CREATE TABLE countries(
	countryId SERIAL PRIMARY KEY NOT NULL,
	countryName VARCHAR(255) NOT NULL
);

INSERT INTO countries (countryName) VALUES ('UK'), ('Australia');

CREATE TABLE sites(
	siteId SERIAL PRIMARY KEY NOT NULL,
	siteName VARCHAR(50) NOT NULL,
	countryId INT NOT NULL,
		FOREIGN KEY (countryId)
		REFERENCES countries(countryid)
);

INSERT INTO sites (siteName, countryId) VALUES ('Wavendon', 1);
INSERT INTO sites (siteName, countryId) VALUES ('London', 1);
INSERT INTO sites (siteName, countryId) VALUES ('Brisbane', 2);

CREATE TABLE whenLoaded (
	whenLoadedId SERIAL PRIMARY KEY NOT NULL,
	whenLoaded VARCHAR(50) NOT NULL
);

INSERT INTO whenLoaded (whenLoaded) VALUES ('IS_INITIAL'), ('IS_OTHER');

CREATE TABLE companies(
	companyId SERIAL PRIMARY KEY NOT NULL,
	companyName VARCHAR(50) NOT NULL,
	whenLoadedId INT NOT NULL,
		FOREIGN KEY (whenLoadedId)
		REFERENCES whenLoaded(whenLoadedId)
);

INSERT INTO companies(companyname, whenLoadedId) VALUES ('BP', 1),('City',1),('Cimbali',1), ('Diebold Nixdorf',1),('GVR',1),('I4Retail',1);

CREATE TABLE visitors(
    visitorId SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(50) NOT NULL,
    companyId INT NOT NULL,
		FOREIGN KEY (companyId)
		REFERENCES companies(companyId),
    imageLink VARCHAR(50)
);

ALTER TABLE visitors ADD COLUMN createdDateTime TIMESTAMP;
ALTER TABLE visitors ALTER COLUMN createdDateTime SET DEFAULT now();

CREATE TABLE visits(
	visitId SERIAL PRIMARY KEY NOT NULL,
	visitorId INT NOT NULL,
		FOREIGN KEY (visitorId)
		REFERENCES visitors(visitorId),
	siteId INT NOT NULL,
		FOREIGN KEY (siteId)
		REFERENCES sites(siteId),
	purpose VARCHAR(255)
);

-- visitor from company already listed
INSERT INTO visitors(name, companyId) VALUES ('Bob',1);
INSERT INTO visits(visitorId, purpose, siteId) VALUES (1, 'testing previously loaded company', 1);

INSERT INTO visitors(name, companyId) VALUES ('Hannah',2);
INSERT INTO visits(visitorId, purpose, siteId) VALUES (2, 'testing previously loaded company', 1);

INSERT INTO visitors(name, companyId) VALUES ('Jill',2);
INSERT INTO visits(visitorId, purpose, siteId) VALUES (3, 'testing previously loaded company', 2);

INSERT INTO visitors(name, companyId) VALUES ('John',3);
INSERT INTO visits(visitorId, purpose, siteId) VALUES (4, 'testing previously loaded company', 2);

INSERT INTO visitors(name, companyId) VALUES ('Jack',4);
INSERT INTO visits(visitorId, purpose, siteId) VALUES (5, 'testing previously loaded company', 3);

-- visitor from 'Other' company
INSERT INTO companies(companyname, whenLoadedId) VALUES ('other_company_one',2);
INSERT INTO companies(companyname, whenLoadedId) VALUES ('other_company_two',2);
INSERT INTO companies(companyname, whenLoadedId) VALUES ('other_company_three',2);
INSERT INTO visitors(name, companyId) VALUES ('Johnny',7);
INSERT INTO visitors(name, companyId) VALUES ('Hawkeye',8);
INSERT INTO visitors(name, companyId) VALUES ('Thor',8);
INSERT INTO visitors(name, companyId) VALUES ('BillyBobThornton',9);
INSERT INTO visits(visitorId, purpose, siteId) VALUES (6, 'testing new company', 2);
INSERT INTO visits(visitorId, purpose, siteId) VALUES (7, 'testing new company also', 2);
INSERT INTO visits(visitorId, purpose, siteId) VALUES (8, 'testing new company in other site', 3);
INSERT INTO visits(visitorId, purpose, siteId) VALUES (9, 'testing new company in other site', 2);

-- 8 visitors, 1 visit per visitor
-- 5 using previously loaded companies in UK
-- 3 with added companies
-- 6 visitors in UK
-- 1 in Oz, Brisbane
CREATE OR REPLACE FUNCTION get_results() RETURNS TABLE (companyname varchar(255), siteName varchar(255), countryName varchar(255), countofvisits int) AS $$
begin

DROP TABLE IF EXISTS results; 
CREATE TABLE results(companyname varchar(255), siteName varchar(255), countryName varchar(255), countofvisits int);

	WITH 
	countCompanies AS (
	select count(visitId) as specTotal,
	companies.companyName,
	sites.siteName as siteName,
	countries.countryName as countryName
	FROM visits
		inner join visitors 
			on visits.visitorId = visitors.visitorId  
				inner join sites 
					on visits.siteId = sites.siteId
				inner join countries 
					on sites.countryId = countries.countryId
				inner join companies 
					on visitors.companyId = companies.companyId
					WHERE companies.whenLoadedId != 2
					GROUP BY sites.siteName, companies.companyName, countries.countryName
	) INSERT INTO results (companyname, countofvisits, siteName, countryName) SELECT countCompanies.companyName, countCompanies.specTotal, countCompanies.siteName, countCompanies.countryName FROM countCompanies;

	WITH 
	otherCompanies AS (
select 
		count(visitId) as otherTotal,
		'other' as companyName,
		sites.siteName,
		countries.countryName
	FROM visits
		inner join visitors 
			on visits.visitorId = visitors.visitorId 
				inner join sites
					on visits.siteId = sites.siteId
				inner join countries 
					on sites.countryId = countries.countryId
				inner join companies 
					on visitors.companyId = companies.companyId
	WHERE companies.whenLoadedId = 2
	GROUP BY sites.siteName, countries.countryName
	)
	INSERT INTO results (companyname, countofvisits, siteName, countryName) SELECT otherCompanies.companyName, otherCompanies.otherTotal, otherCompanies.siteName, otherCompanies.countryName FROM otherCompanies;

	RETURN QUERY select * from results;
end;
$$ LANGUAGE plpgsql;