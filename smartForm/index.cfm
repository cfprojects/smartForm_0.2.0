<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
		<title></title>
		<style type="text/css">
		</style>
	</head>
	<body>
    <cfdump var="#form#" label="FORM Scope">
		<br />
		<hr />
		<cfoutput>
			<form action="index.cfm" method="post">
        <h3>Pure Struct Notation</h3>
        <input type="text" size="50" name="normal_field" value="normal_field" /><br />
        <input type="text" size="50" name="test.key1" value="test.key1" /><br />
        <input type="text" size="50" name="test.sub1.key1" value="test.sub1.key1" /><br />
        
        <h3>Implicit Array</h3>
        <h4>Don't Do This</h4>
        <p>
          This is bad coding and you should feel bad for coding it. Just make
          multiple form fields with the same name. The submission process will
          convert the values into a comma separated list.
        </p>
        <input type="text" size="50" value="books[1]" /><br />
        
        <h4>Do This</h4>
        <p>All these fields have a name attribute of "books"</p>
        <input type="text" size="50" name="books" value="books1" /><br />
        <input type="text" size="50" name="books" value="books2" /><br />
        <input type="text" size="50" name="books" value="books3" /><br />
        <input type="text" size="50" name="books" value="books4" /><br />
        
        <h3>Array Containing Single-Level Struct</h3>
        <input type="text" size="50" name="lines[1].foo" value="lines[1].foo" /><br />
        <input type="text" size="50" name="lines[1].bar" value="lines[1].bar" /><br />
        <h4>Array out of sequence</h4>
        <input type="text" size="50" name="lines[3].foo" value="lines[3].foo" /><br />
        
        <h3>Array with multi-level struct(s)</h3>
        <input type="text" size="50" name="lines[1].hello.kitty" value="lines[1].hello.kitty" /><br />
        
        <h3>Nested Array with single-level struct</h3>
        <input type="text" size="50" name="order.lines[1].firstname" value="order.lines[1].firstname" /><br />
        <input type="text" size="50" name="order.lines[1].lastname" value="order.lines[1].lastname" /><br />
        
        <h3>More Complicated Nesting</h3>
        <input type="text" size="50" name="hiss[1].boom[1].bah" value="hiss[1].boom[1].bah" /><br />
        <input type="text" size="50" name="hiss[1].boom[2].bah" value="hiss[1].boom[2].bah" /><br />
        
				<label>Smart Form?</label>
					<input type="checkbox" name="_smart_form" value="yes" #(form._smart_form EQ 'yes' ? 'checked="checked"' : '')# />
					<br />
					<br />
				<input type="submit" value="Do It!" />
			</form>
		</cfoutput>
	</body>
</html>