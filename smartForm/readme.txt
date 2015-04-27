The FORM scope is fairly narrow in what it can hold within it. For starters, it can only hold keys directly within the FORM struct. Nested objects and collections are not possible using vanilla CF methods. Take the following as examples.

FORM.foo.bar

You would expect the key 'foo' in the FORM scope to contain a structure with the key of 'bar'. Vanilla CF treats it like FORM['foo.bar']. This is not nice because we cannot perform manipulation of all keys within FORM.foo without complicated ColdFusion code.

FORM.foo[1].bar

This is another interesting one. You would expect the key 'foo' to contain an array of structs for the purpose of looping over each element in the FORM.foo array. However, vanilla CF treats it as FORM['foo[1].bar']. Again, this is highly unusable on the receiving end as I would need to perform some complicated logic to separate each individual 'foo' entry for processing.


The smartForm function aims to alleviate these woes with the FORM scope by transforming the values into the collections and objects that you would expect in the examples above. The function will look for FORM._smart_form = 'yes' to transform the FORM scope, otherwise it will leave the FORM scope alone. This is useful because you can call this function in Application.cfc in onRequestStart() to transform the scope for any form that wishes to make use of this functionality.


CHANGES
0.2
- Now with recursion! The function will now dive as deep as needed to return a clean struct.
0.1.2
- Bug fix dealing with missing variables within array collections