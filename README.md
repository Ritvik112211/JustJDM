# JustJDM
This page documents the development journey of this project from initial concept to implementation and refinement.
For the the final report, please visit my portfolio at https://ritvikawasthi.me.

## About JustJDM
This project was completed to support a real, Japan-based exporter of JDM automotive parts, referred to here as **JustJDM** for confidentiality. I cleaned and structured previously messy operational data and built an executive dashboard for ongoing internal use. Using insights from the dashboard, I analyzed growth quality, unit economics, and pricing dynamics to help the business better understand scalability, margin resilience, and areas for execution-led improvement.

## Data Structure

This analysis consolidates data from three key sources:

**SalesLog_JDM_Raw.csv -** Order-level sales data including dates, products, units, pricing, logistics, returns, and agent details.

**JDM_Discount_Raw.csv -** Discount policy data defining promotional rules, customer-based pricing, and seasonal adjustments.

**Inv_JDM_Raw.csv -** Product and inventory master data with pricing, stock levels, supplier info, and lifecycle details.

This final data model integrates product master data, transactional sales records, and discount rules into a single analytical structure. **Inv_JDM cont**ributes detailed product attributes such as brand, category, platform, pricing, supplier details, and image references. **SalesLog_JDM** captures each transaction at the order level, including Product_ID, Order_Date, customer type, country, units sold, revenue, and cost fields, acting as the central fact table. **JDM_Discount** defines the applicable discount structures, including discount bands and promotional rules, which are linked to sales records to reflect pricing adjustments. In the underlying relational structure, products connect to sales through a one-to-many relationship on **Product_ID**, and discount rules connect to sales through discount-related fields, with no direct relationship between products and discounts outside of the sales transactions.

<img width="820" height="516" alt="image" src="https://github.com/user-attachments/assets/9f81de03-9c32-45be-8ace-c0ccae1cf3e1" />

Further, during development, Year-over-Year (YoY) calculations returned blank values or incorrect outputs when filtering by a specific year. The issue stemmed from relying directly on the transaction table’s Order_Date field for time comparisons.

The transaction table:
* Did not contain a continuous calendar.
* Included DateTime values (date + time).
* Was being used directly in slicers, preventing proper prior-year evaluation.

As a result, Power BI’s time-intelligence functions (e.g., SAMEPERIODLASTYEAR) could not correctly determine the previous period.

To resolve the Year-over-Year calculation issues, the data model was restructured by introducing a dedicated Date table to serve as a continuous calendar dimension. The original transaction table relied directly on a DateTime field, which included time components and lacked a complete calendar structure, preventing Power BI’s time-intelligence functions from correctly identifying prior periods. A calculated column (OrderDate_Only) was created to remove the time portion from the transaction date, enabling a clean one-to-many relationship between Date[Date] (one side) and JDM_FinalDataset_2025-11-23_updated[OrderDate_Only] (many side). This relationship allows the Date table to filter the fact table properly, ensuring that year slicers and functions such as SAMEPERIODLASTYEAR reference a structured, continuous calendar. As a result, YoY calculations became accurate, stable, and aligned with best-practice star schema modeling.

<img width="574" height="274" alt="image" src="https://github.com/user-attachments/assets/03831af1-7697-4752-95c2-b9ca138e2ecc" />

## Setup for Creation

### Using Docker container to run Azure Data Studios

As a Mac user looking to learn Microsoft SQL Server an enterprise standard database deeply integrated with Azure I faced a key challenge: SQL Server is designed primarily for Windows. While switching to Mac-friendly databases like MySQL was an option, it would have taken me away from the tools and workflows used in real-world environments. To stay aligned with industry practices, I opted to run SQL Server on my Mac using Docker, paired with Azure Data Studio for management. This approach resolved the compatibility issue and provided valuable experience working with containerized environments an essential skill in today’s cloud-driven development landscape.

**PROCESS:** 

**STEP 1:** Downloaded Docker Desktop from Docker’s official website[1] and completed the installation. After setup, verified Docker was running correctly.

**STEP 2:**  Pulled SQL Server Docker Image

In Terminal, executed the following command to pull Microsoft’s official Azure SQL Edge image:

```bash
docker pull [mcr.microsoft.com/azure-sql-edge](http://mcr.microsoft.com/azure-sql-edge)
```

**STEP 3:** Ran SQL Server Instance in Docker

Started a SQL Server container with the following command:

```bash
docker run -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD=SamPlePwD123' -p 1433:1433 --name azuresaledge -v salvolume:/var/opt/mssal -d [mcr.microsoft.com/azure-sal-edge](http://mcr.microsoft.com/azure-sal-edge)
```

**About the command:** 

- Accepted the license agreement.
- Set the system administrator (`sa`) password.
- Mapped port 1433, enabling my Mac to communicate with the SQL Server container.
- Created a persistent Docker volume named `salvolume`, ensuring database data remains intact even if the container stops or is removed.
- Ran the container in detached (background) mode.

**STEP 4:** Installed Azure Data Studio (ADS)

Downloaded and installed Azure Data Studio for macOS from Microsoft’s website. This tool serves as the graphical interface for managing SQL Server databases.

**STEP 5:** Connected Azure Data Studio to SQL Server Container

Configured a new connection in Azure Data Studio with the following settings:

- **Server Name:** `localhost`
- **Authentication Type:** SQL Login
- **Username:** `sa`
- **Password:** `SamPlePwD123` (set during container run)

**STEP 6**: Verified Setup

Created a test database and ran sample queries to confirm that SQL Server was running correctly within the Docker container and fully manageable through Azure Data Studio

### Running Power BI using Parallels emulator

Further, wanting to stay in the Microsoft ecosystem using a Mac and later realizing that incompatibility and limited usage of the online version. I faced the challenge of accessing Power BI, which is primarily designed for Windows. To bridge this compatibility gap without switching devices, I used Parallels Desktop’s free trial version to run Power BI smoothly on my Mac. Setting up Windows was simple. 

**Installed Parallels Desktop** – Downloaded from the official site, installed, and launched it.

**Set Up Windows** – Used Parallels’ built-in option to download Windows 11 

**Allocate Resources** – In VM settings, gave Windows 4 GB RAM and 2 CPUs.

**Enable Sharing** – Turned on Mac folder and clipboard sharing so files move easily between macOS and Windows.

**Update Windows** – Installed all Windows updates before adding anything else.

**Install Power BI** – Downloaded from the Microsoft Store (or the MSI installer if the Store version didn’t appear).

**First Run** – Signed in, set regional settings, and connected shared Mac folders so I could open data files directly

## Dashboard Creation 

### Design philosophy
The dashboard was intentionally designed for users with little to no familiarity with cars or automotive parts. Clarity and intuitive navigation were the primary priorities.
At the top right where users’ attention naturally gravitates first, I placed the most critical elements: a visual blueprint showing where each part fits within the vehicle, along with year selection controls for quick filtering. 

As users move downward and toward the left, the information becomes progressively more detailed and granular, supporting deeper analysis without overwhelming them upfront. Rather than relying on abstract icons, I incorporated real images of the parts to make identification immediate and intuitive. 

The overall design philosophy centers on reducing cognitive load and enabling fast, confident decision-making ensuring even users with limited automotive knowledge can quickly understand what they’re looking at and why it matters.

<img width="632" height="357" alt="image" src="https://github.com/user-attachments/assets/7644f6d8-76ff-4d4a-87ed-d9cf716d1a56" />

### Displaying Product Images Dynamically
Since I didn’t have local copies of the product images, I hosted them online using [*imgbb.com](http://imgbb.com)* After uploading each image, I copied the direct link and stored it in a new column called `image_URL` in my product description table. Once imported into Power BI, I set the column’s **Data Category** to *Image URL* so the dashboard could display the actual images instead of plain text links. This not only made the visuals more engaging but also kept the report lightweight and quick to load.

### Adding Instant KPI Insights using DAX
I structured the dashboard to provide a complete performance view by combining scale, momentum, and unit economics metrics. Total Revenue and Total Profit measure business size, while YoY Revenue and YoY Profit reveal growth trends and performance acceleration or slowdown. To understand underlying drivers, I incorporated Realized Price %, Average Order Value (AOV), and SKU Margin Spread to evaluate pricing discipline, customer purchasing behavior, and product-level profitability dispersion. Together, these KPIs move beyond descriptive reporting and enable diagnostic analysis of whether growth is volume-driven, pricing-led, or mix-dependent, aligning the dashboard with financial operations and transformation best practices.

***Formulas for KPIs :***

Total Revenue
```DAX
Total Revenue =
SUM ( 'JDM_FinalDataset_2025-11-23_updated'[Revenue] )
```
Total Profit
```DAX
Total Profit =
SUM ( 'JDM_FinalDataset_2025-11-23_updated'[Profit] )
```
Total Units Sold
```DAX
Total Units Sold =
SUM ( 'JDM_FinalDataset_2025-11-23_updated'[Units_Sold] )
```
Revenue YoY %
```DAX
Revenue LY =
CALCULATE (
    [Total Revenue],
    SAMEPERIODLASTYEAR ( 'Date'[Date] )
)

Revenue YoY % =
DIVIDE (
    [Total Revenue] - [Revenue LY],
    [Revenue LY]
)
```
Profit YoY %
```DAX
Profit LY =
CALCULATE (
    [Total Profit],
    SAMEPERIODLASTYEAR ( 'Date'[Date] )
)

Profit YoY % =
DIVIDE (
    [Total Profit] - [Profit LY],
    [Profit LY]
)
```
Realized Price %
```DAX
(Assuming you have a List_Price column)

Realized Price % =
DIVIDE (
    [Total Revenue],
    SUM ( 'JDM_FinalDataset_2025-11-23_updated'[List_Price] )
)
```

Average Order Value (AOV)
```DAX
(Requires Order_ID column)

Total Orders =
DISTINCTCOUNT ( 'JDM_FinalDataset_2025-11-23_updated'[Order_ID] )

AOV =
DIVIDE ( [Total Revenue], [Total Orders] )
```
SKU Margin Spread %
```DAX
Min SKU Margin =
MIN ( 'JDM_FinalDataset_2025-11-23_updated'[Contribution_per_Unit] )

Max SKU Margin =
MAX ( 'JDM_FinalDataset_2025-11-23_updated'[Contribution_per_Unit] )

SKU Margin Spread % =
DIVIDE (
    [Max SKU Margin] - [Min SKU Margin],
    [Max SKU Margin]
)
```
