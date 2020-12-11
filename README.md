# visits_reporting
Brief POC for recording visits to stores by companies, and a PowerBI report for summarising if visits are from previously known companies or not.

The idea is that if a visitor attends a store, this is recorded as a visit. 
Each visitor represents a company. 
Each store may be in a particular country.
We have a list of companies that we are interested in reporting on. However, we still want to find the details of what companies these visitors represent for reporting purposes.
This Docker project sets out a POC for solving this. Essentially, each company has a value representing if it is one of the companies we are interested in reporting (whenLoaded).
This value is used in an SQL function and displayed in the PowerBI report.
