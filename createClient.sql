USE [GFVirtualFinancesMain]
GO
/****** Object:  StoredProcedure [person].[CreateClient]    Script Date: 20.04.2018 08:45:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--TRUNCATE TABLE common.Addresses
--TRUNCATE TABLE common.Contacts
--TRUNCATE TABLE person.Clients
--TRUNCATE TABLE person.GeneralDetails




ALTER PROCEDURE [person].[CreateClient] 
@Data XML 
as 

BEGIN TRY
BEGIN TRAN

DECLARE @NipFromXML AS varchar(15)
SET @NipFromXML = (SELECT m.value('NIP[1]', 'char(10)') FROM @Data.nodes('//Client') as T(m))

IF NOT EXISTS (SELECT Nip FROM person.Clients WHERE NIP = @NipFromXML)
BEGIN

-- insert do GENERAL DETAILS
INSERT INTO person.GeneralDetails(Name, Sha256)
Select 
	k.value('Name[1]' , 'nvarchar(500)') as [name],
	k.value('Sha256[1]', 'nvarchar(300)') as sha256  
FROM @Data.nodes('//GeneralDetails') as T(k);



-- insert do CLIENTS
INSERT INTO person.Clients(IdentityId, NIP, Acronim, GeneralDetailId, UserName)
Select
	m.value('IdentityId[1]', 'nvarchar(450)') as identityid,
	m.value('NIP[1]', 'char(10)') as nip,
	m.value('Acronim[1]', 'nvarchar(100)') as acronim,
	(Select Id from person.GeneralDetails where Sha256 = m.value('../GeneralDetails[1]/Sha256[1]', 'nvarchar(300)')) as hashsha256,
	m.value('UserName[1]', 'nvarchar(50)') as username
From @Data.nodes('//Client') as T(m);

--Insert do CONTACT TYPES
--INSERT INTO common.ContactTypes([Name])
--	select 
--		r.value('ContactType[1]', 'nvarchar(50)') as contacttype
--		from @Dane.nodes('//Contact') as T(r)
--		where r.value('ContactType[1]', 'nvarchar(50)') NOT IN (Select [Name] from common.ContactTypes);



--insert do CONTACTS
INSERT INTO common.Contacts(Value, ContactTypeId, GeneralDetailId)
Select
	r.value('Value[1]', 'nvarchar(200)') as value,
	(Select Id from common.ContactTypes Where name = r.value('ContactType[1]', 'nvarchar(50)')) as contacttypeid,
	(Select Id from person.GeneralDetails Where Sha256 = r.value('../../../GeneralDetails[1]/Sha256[1]', 'nvarchar(300)')) as sha256
From @Data.nodes('//Contact') as T(r);



--insert do ADDRESS TYPES
--INSERT INTO common.AddressTypes(Name)
--Select
--	a.value('AddressType[1]', 'nvarchar(50)') as addresstype
--From @Dane.nodes('//Address') as T(a)
--where a.value('AddressType[1]', 'nvarchar(50)') NOT IN (select Name from common.AddressTypes)


--insert do ADDRESSES
INSERT INTO common.Addresses(City, ZipCode, Street, HouseNumber, FlatNumber, CountryId, AddressTypeId, GeneralDetailId)
Select
	a.value('City[1]' , 'nvarchar(100)') as city,
	a.value('ZipCode[1]' , 'nvarchar(10)') as zipcode,
	a.value('Street[1]', 'nvarchar(100)') as street,
	a.value('HouseNumber[1]' , 'nvarchar(10)') as housenumber,
	a.value('FlatNumber[1]', 'int') as flatnumber,
	(Select Id from common.Countries where Code = a.value('CountryCode[1]' , 'char(4)')) as countrycode,
	(Select Id from common.AddressTypes where Name = a.value('AddressType[1]', 'nvarchar(50)')) as addresstype,
	(Select Id from person.GeneralDetails where Sha256 = a.value('../../../GeneralDetails[1]/Sha256[1]', 'nvarchar(300)')) as sha256
From @Data.nodes('//Address') as T(a);

DECLARE @TempVar as TABLE
(ClientId uniqueidentifier)

INSERT INTO @TempVar (ClientId)
SELECT 
	Clients.Id
FROM @Data.nodes('//Client') as T(k) JOIN person.Clients ON NIP = k.value('NIP[1]', 'char(10)')

SELECT * FROM @TempVar

END

COMMIT TRAN
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
	ROLLBACK;
	throw
END CATCH
