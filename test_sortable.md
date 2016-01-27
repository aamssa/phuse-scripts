[[show=" " hide="Hide"](collapsible.md)]
[[html](html.md)]


&lt;html&gt;


> 

&lt;head&gt;


> > 

&lt;script type="text/javascript" src="http://www.google.com/jsapi"&gt;



&lt;/script&gt;


> > 

&lt;script type="text/javascript"&gt;


> > > google.load("visualization", "1", {packages:["table"]});
> > > google.setOnLoadCallback(drawTable);
> > > function drawTable() {
> > > var data = new google.visualization.DataTable();


> data.addColumn('string', 'Department');
> data.addColumn('number', 'Revenue');
> data.addColumn('number', 'Change');
> data.addColumn('boolean', 'Staff Bonus');

> data.addRows(5);

> data.setCell(0, 0, 'Shoes');
> data.setCell(0, 1, 10000, '�10,000');
> data.setCell(0, 2, 12, '12.0%');
> data.setCell(0, 3, true);

> data.setCell(1, 0, 'Sports');
> data.setCell(1, 1, 22000, '�22,000');
> data.setCell(1, 2, -7.3, '-7.3%');
> data.setCell(1, 3, false);

> data.setCell(2, 0, 'Toys');
> data.setCell(2, 1, 4000, '�4,000');
> data.setCell(2, 2, 0, '0%');
> data.setCell(2, 3, false);

> data.setCell(3, 0, 'Electronics');
> data.setCell(3, 1, 31000, '�31,000');
> data.setCell(3, 2, -2.1, '-2.1%');
> data.setCell(3, 3, false);

> data.setCell(4, 0, 'Food');
> data.setCell(4, 1, 80000, '�8,000');
> data.setCell(4, 2, 22, '22.0%');
> data.setCell(4, 3, true);

> var table = new google.visualization.Table(document.getElementById('arrowformat\_div'));

> var formatter = new google.visualization.TableArrowFormat();
> formatter.format(data, 2); // Apply formatter to third column

> table.draw(data, {allowHtml: true, showRowNumber: true, alternatingRowStyle: true});
> > }
> > 

&lt;/script&gt;



> 

&lt;/head&gt;



> 

&lt;body&gt;


> > <div></div>

> 

&lt;/body&gt;




&lt;/html&gt;



[[/html]]
[[/collapsible]]

from prettytable import PrettyTable

x = PrettyTable(["City name", "Area", "Population", "Annual Rainfall"])
x.align["City name"] = "l" # Left align city names
x.padding\_width = 1 # One space between column edges and contents (default)
x.add\_row(["Adelaide",1295, 1158259, 600.5])
x.add\_row(["Brisbane",5905, 1857594, 1146.4])
x.add\_row(["Darwin", 112, 120900, 1714.7])
x.add\_row(["Hobart", 1357, 205556, 619.5])
x.add\_row(["Sydney", 2058, 4336374, 1214.8])
x.add\_row(["Melbourne", 1566, 3806092, 646.9])
x.add\_row(["Perth", 5386, 1554769, 869.4])
print x



### Example ###
This is an example of a small ''sortable'' table.

{| class="wikitable sortable" border="1"
|-
! name
! data
! more data
|-
| cats
| 273
| 53
|-
| dogs
| 65
| 8,492
|-
| mice
| 1,649
| 548
|}


### Tables with complex headers ###

Tables with more complex headers than before now sort correctly. For example:

{| class="wikitable sortable"
|-
! rowspan="2" | name
! colspan="2" | Data columns
! rowspan="2" | Another column
|-
! data
! more data
|-
| cats
| 273
| 53
| 1
|-
| dogs
| 65
| 8,492
| 2
|-
| mice
| 1,649
| 548
| 3
|}