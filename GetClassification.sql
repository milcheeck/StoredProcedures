USE [GFVirtualFinancesMain]
GO
/****** Object:  StoredProcedure [alg].[GetClassificationByClientId]    Script Date: 20.04.2018 08:38:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [alg].[GetClassificationByClientId]
@ClientId as nvarchar(450)

AS


SELECT (SELECT  Class.Id as ClassificationId, 
				Class.Name as [Name], 
				CT.Name AS ClassificationType,
				Class.InvoiceQuantity as InvoiceQuantity,
				Class.ClientId AS ClientId,
				--Zagnieżdżenie Reguł 
			    (SELECT DISTINCT R.Id as RuleId,
					--Dane Contractora 
					(SELECT R.ContractorId, ContrGen.Name, Contr.NIP, Contr.Acronim, Contr.Description,
						--ContractorContacts
						(SELECT ContrGen.Name, C.Value FROM common.Contacts as C WHERE C.GeneralDetailId = ContrGen.Id for json path) as ContractorContacts,
						--ContractorsAddresses
						(SELECT ContrGen.Name, A.City, A.ZipCode, A.Street, A.HouseNumber, A.FlatNumber, Coun.Code, Coun.Name as CountryName FROM common.Addresses AS A JOIN common.Countries as Coun ON A.CountryId = Coun.Id WHERE A.GeneralDetailId = ContrGen.Id for json path ) as ContractorAddresses
						 FROM person.Contractors as Contr JOIN person.GeneralDetails AS ContrGen ON Contr.GeneralDetailId = ContrGen.Id WHERE R.ContractorId = Contr.Id 
							for json path) as ContractorData,
					--Zagnieżdżenie Tagów
				    (SELECT T.Id as tagid, T.Name as tagname FROM alg.Tags AS T JOIN alg.RulesTags as RT ON  T.Id=RT.TagId WHERE R.Id=RT.RuleId FOR JSON PATH) AS TagsCollection  
			     FROM alg.Rules AS R JOIN alg.RulesTags as RT ON R.Id = RT.RuleId
								/*JOIN alg.Classifications AS C ON C.Id = R.ClassificationId*/ WHERE Class.Id = R.ClassificationId for json path) as RulesCollection
				--(SELECT  Contr.Id, Contr.NIP FROM person.Contractors as Contr JOIN alg.Rules as Rls ON Rls.ContractorId = Contr.Id for json path) as ContractorData
		
       FROM alg.Classifications as Class JOIN alg.ClassificationTypes AS CT ON Class.ClassificationTypeId = CT.Id
	   WHERE Class.ClientId = @ClientId AND Class.IsDeleted = 0
										   for json path) AS ClassificationCollection

		
FOR JSON PATH, root('RESULTS')
