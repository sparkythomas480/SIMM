CREATE DATABASE SIMM
GO

USE SIMM
GO

CREATE SCHEMA Constants
GO

CREATE TABLE [Constants].[ProductClasses]
(
    Id TINYINT IDENTITY(1,1) NOT NULL,
    [Value] NVARCHAR(9) NOT NULL,
    CONSTRAINT PK_ProductClasses PRIMARY KEY CLUSTERED (Id),
    CONSTRAINT U_ProductClassses UNIQUE NONCLUSTERED ([Value])
)
GO

INSERT INTO [Constants].[ProductClasses]([Value]) VALUES ('RatesFX'), ('Credit'), ('Equity'), ('Commodity')
GO

CREATE TABLE  [Constants].[ISOCurrencies]
(
    Id TINYINT IDENTITY(1,1) NOT NULL,
    [Value] NVARCHAR(3) NOT NULL,
    CONSTRAINT PK_ISOCurrencies PRIMARY KEY CLUSTERED (Id),
    CONSTRAINT U_ISOCurrencies UNIQUE NONCLUSTERED ([Value])
)
GO

-- Get complete list later but check that tinyint as the pkid is enough to hold them all
INSERT INTO [Constants].[ISOCurrencies]([Value]) VALUES ('AUD'), ('BRL'), ('CHF'), ('CNY'), ('EUR'), ('JPY'), ('MXN'), ('USD')
GO

CREATE TABLE  [Constants].[IRCurveBuckets]
(
    Id TINYINT IDENTITY(1,1) NOT NULL,
    [Value] TINYINT NOT NULL,
    CONSTRAINT PK_IRCurveBuckets PRIMARY KEY CLUSTERED (Id),
    CONSTRAINT U_IRCurveBuckets UNIQUE NONCLUSTERED ([Value])
)
GO

INSERT INTO [Constants].[IRCurveBuckets]([Value]) VALUES (1), (2), (3)
GO

CREATE TABLE  [Constants].[IRTenors]
(
    Id TINYINT IDENTITY(1,1) NOT NULL,
    [Value] NVARCHAR(3) NOT NULL,
    CONSTRAINT PK_IRTenors PRIMARY KEY CLUSTERED (Id),
    CONSTRAINT U_IRTenors UNIQUE NONCLUSTERED ([Value])
)
GO

INSERT INTO [Constants].[IRTenors]([Value]) VALUES ('2w'), ('1m'), ('3m'), ('6m'), ('1y'), ('2y'), ('3y'), ('5y'), ('10y'), ('15y'), ('20y'), ('30y')
GO

CREATE TABLE [Constants].[IRSubCurves]
(
    Id TINYINT IDENTITY(1,1) NOT NULL,
    [Value] NVARCHAR(9) NOT NULL,
    CONSTRAINT PK_IRSubCurves PRIMARY KEY CLUSTERED (Id),
    CONSTRAINT U_IRSubCurves UNIQUE NONCLUSTERED ([Value])
)
GO

INSERT INTO [Constants].[IRSubCurves]([Value]) VALUES ('Prime'), ('Municipal'), ('OIS'), ('Libor1m'), ('Libor3m'), ('Libor6m'), ('Libor12m')
GO

CREATE TABLE [Constants].[IRCurveRiskWeights]
(
    IRCurveBucketId TINYINT NOT NULL,
    IRTenorId TINYINT NOT NULL,
    [Value] FLOAT NOT NULL,
    CONSTRAINT PK_IRCurveRiskWeights PRIMARY KEY CLUSTERED (IRCurveBucketId, IRTenorId),
    CONSTRAINT FK_IRCurveRiskWeights_IRCurveBuckets FOREIGN KEY (IRCurveBucketId) REFERENCES [Constants].[IRCurveBuckets](Id),
    CONSTRAINT FK_IRCurveRiskWeights_IRTenors FOREIGN KEY (IRTenorId) REFERENCES [Constants].[IRTenors](Id)
)
GO

CREATE TABLE #IRCurveRiskWeights
(
    Bucket TINYINT NOT NULL,
    Tenor NVARCHAR(9) NOT NULL,
    [Value] FLOAT NOT NULL
)
GO

INSERT INTO #IRCurveRiskWeights(Bucket, Tenor, [Value])
VALUES
(1, '2w', 109),
(1, '1m', 106),
(1, '3m', 91),
(1, '6m', 69),
(1, '1y', 68),
(1, '2y', 68),
(1, '3y', 66),
(1, '5y', 61),
(1, '10y', 59),
(1, '15y', 56),
(1, '20y', 57),
(1, '30y', 55),
(2, '2w', 15),
(2, '1m', 21),
(2, '3m', 10),
(2, '6m', 10),
(2, '1y', 11),
(2, '2y', 15),
(2, '3y', 18),
(2, '5y', 23),
(2, '10y', 25),
(2, '15y', 23),
(2, '20y', 23),
(2, '30y', 25),
(3, '2w', 171),
(3, '1m', 102),
(3, '3m', 94),
(3, '6m', 96),
(3, '1y', 105),
(3, '2y', 96),
(3, '3y', 99),
(3, '5y', 93),
(3, '10y', 99),
(3, '15y', 100),
(3, '20y', 101),
(3, '30y', 96)
GO

INSERT INTO [Constants].[IRCurveRiskWeights]
SELECT ircb.id, irt.id, ircrw.[Value] FROM #IRCurveRiskWeights ircrw
JOIN [Constants].[IRCurveBuckets] ircb ON ircb.[Value] = ircrw.Bucket
JOIN [Constants].[IRTenors] irt ON irt.[Value] = ircrw.Tenor
GO

CREATE SCHEMA Sensitivities
GO

CREATE TABLE [Sensitivities].[IRCurve]
(
    ProductClassId TINYINT NOT NULL,
    ISOCurrencyId TINYINT NOT NULL,
    IRCurveBucketId TINYINT NOT NULL,
    IRTenorId TINYINT NOT NULL,
    IRSubCurveId TINYINT NOT NULL,
    [Value] FLOAT NOT NULL,
    CONSTRAINT PK_IRCurve PRIMARY KEY CLUSTERED (ProductClassId, ISOCurrencyId, IRCurveBucketId, IRTenorId, IRSubCurveId),
    CONSTRAINT FK_IRCurve_ProductClasses FOREIGN KEY (ProductClassId) REFERENCES [Constants].[ProductClasses](Id),
    CONSTRAINT FK_IRCurve_ISOCurrencies FOREIGN KEY (ISOCurrencyId) REFERENCES [Constants].[ISOCurrencies](Id),
    CONSTRAINT FK_IRCurve_IRCurveBuckets FOREIGN KEY (IRCurveBucketId) REFERENCES [Constants].[IRCurveBuckets](Id),
    CONSTRAINT FK_IRCurve_IRTenors FOREIGN KEY (IRTenorId) REFERENCES [Constants].[IRTenors](Id),
    CONSTRAINT FK_IRCurve_IRSubCurves FOREIGN KEY (IRSubCurveId) REFERENCES [Constants].[IRSubCurves](Id)
)
GO

INSERT INTO [Sensitivities].[IRCurve]
SELECT pc.Id, ic.Id, ircb.Id, irt.Id, irsc.Id, max(sd.AmountUSD) FROM [Sensitivities].[ISDA-SIMM-UnitTesting-v2.6.5_CRIF] sd
join [Constants].[ProductClasses] pc on sd.ProductClass = pc.[Value]
join [Constants].[ISOCurrencies] ic on sd.Qualifier = ic.[Value]
JOIN [Constants].[IRCurveBuckets] ircb ON sd.Bucket = ircb.[Value]
JOIN [Constants].[IRTenors] irt ON sd.Label1 = irt.[Value]
JOIN [Constants].[IRSubCurves] irsc ON sd.Label2 = irsc.[Value]
WHERE sd.RiskType='Risk_IRCurve'
group by pc.Id, ic.Id, ircb.Id, irt.Id, irsc.Id -- Fix this by adding in PortfolioID, TradeID and CollectRegulations
GO