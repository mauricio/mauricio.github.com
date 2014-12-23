---
layout: post
title: Learning R - Part 1 - Basics
subtitle: this weird and awesome programming language
keywords: R, statistics, programming, introduction
tags:
- useful
---

{% include r-introduction.html %}

[R](http://www.r-project.org/) has two very distinct characteristics, one is having a horrible name that makes it hard to search for stuff about it and the other is being an incredible language (and environment) to do statistical computing and plotting. It was meant to be an GNU implementation of [S](http://en.wikipedia.org/wiki/S_(programming_language)), an older statistical programming language and environment developed at Bell Labs/AT&T.

To follow through this tutorial you'll have to install *R* for your operating system and I would also recommend that you install [R Studio](http://www.rstudio.com/) which is a free GUI tool to work with *R*.

This tutorial assumes you already know the basics of programming.

## Lists and vectors

One of the first distinctions you'll find in *R* when compared to general programming languages is that you'll be working with _many values_ most of the time. Even when working with operations that look like a single variable, you'll end up with a `vector` or a `list`.

Let's look at an example (you can type the code inside an *R* console or _RStudio_ to follow the steps):

{% highlight r %}
value <- 10
class(value)
> [1] "numeric"
value <- c(10)
class(value)
> [1] "numeric"  
value <- c(10, 20, 30)
class(value)
> [1] "numeric"  
{% endhighlight %}

The `<-` operator is the preferred way to assign variables in *R* (you could also use `=`, which has slightly different semantics, but we'll maintain the usual style here). At the first line we assign `10` to the variable `value`, when we check type (using the `class` function), it says it's `numeric`.

Later we use the the `c` function to create a `numeric vector` and when we make the same `class` call on it it produces `numeric` again. Why is that? Because almost everything in *R* is actually a vector of some kind.

You can also create a vector from an interval using the `:` operator as in:

{% highlight r %}
interval <- 1:10
> [1]  1  2  3  4  5  6  7  8  9 10
{% endhighlight %}

Vectors created like this are always inclusive.

In *R* a `vector` is a collection of items all of the same type, so you can't mix numbers and strings. If you want to have a collection with different types, you'd create a list using the `list` function:

{% highlight r %}
items <- list(20, "me")
class(items)
> [1] "list"  
{% endhighlight %}

To access an item inside a vector you use brackets, `[ ]`, and the index of the object you would like to access. Different than other languages you might be used to, in *R* the first item inside a `vector` is at the `1` position instead of `0`. Let's look at an example:

{% highlight r %}
item <- 10
item[1]
> [1] 10
items <- c(10, 40, 90)
items[3]
> [1] 90
items[10]
> [1] NA
{% endhighlight %}

So the indexes for vectors start at `1` and go until it's length, if you try to access an item that doesn't exist, you will get the special value `NA`, which means there is no such value for this specific vector. While related to `NULL`, they're not the same and `NA` values are much more prevalent in *R*  code than `NULL`, most of the time you'll only see `NULL` values being returned in *R* when a function doesn't actually return any value.

Lists are a bit different, if you try to access an element of a list with `[]` you'll see something like this:

{% highlight r %}
simple_list <- list("example", 20)
simple_list[1]
> [[1]]
> [1] "example"
{% endhighlight %}

You're still getting a list back, not exactly what you're looking for, in this case you want to use `[[]]` to get that first element, as in:

{% highlight r %}
simple_list <- list("example", 20)
simple_list[[1]]
> [1] "example"
{% endhighlight %}

When creating lists you can also _name_ the items so you can access them by their names instead of indexes:

{% highlight r %}
named_list <- list(name="John", age=40)
named_list$name
> [1] "John"
named_list$age
> [1] 40
{% endhighlight %}

First you create the list providing a name for every item and then you access them using the `$` operator. You can still use `named_list[[1]]` to get the value `John` here but if you're naming stuff it wouldn't make much sense to do that.

Also, the names don't have to be valid *R* identifiers, you could do something like this:

{% highlight r %}
special_names = list("Maurício Linhares" = "name")
special_names
> $`Maur\303\255cio Linhares`
> [1] "name"

special_names$"Maurício Linhares"
> [1] "name"  
{% endhighlight %}

But I'd say there's very little reason for you to do something like that.

## Basic statistical functions

Let's declare a small vector:

{% highlight r %}
numbers <- c(4, 36, 45, 50, 75)  
{% endhighlight %}

To calculate the mean of this vector, we do:

{% highlight r %}
mean(numbers)
> [1] 42  
{% endhighlight %}

The `mean` function will calculate the arithmetic mean of your vector, in our case it would be:

<math display="block">
  <mfrac>
    <mrow>
      <mn>4</mn>
      <mi>+</mi>
      <mn>36</mn>
      <mi>+</mi>
      <mn>45</mn>
      <mi>+</mi>
      <mn>50</mn>
      <mi>+</mi>
      <mn>75</mn>
    </mrow>
    <mn>5</mn>
  </mfrac>
  <mo>=</mo>
  <mn>42</mn>
</math>

Another common function you could use here is the `median`:

{% highlight r %}
median(numbers)
> [1] 45  
{% endhighlight %}

The median produces the number that's right at the middle of the sorted distribution, in our case, the number right at the middle is `45`. What happens if the vector is even?

{% highlight r %}
even_numbers <- c(4, 36, 40, 45, 50, 75)
median(even_numbers)
> [1] 42.5
{% endhighlight %}

The two numbers right at the middle *of the sorted vector* are summed and then divided by 2. It's important to remember that the median is always calculated from the sorted vector, if you give it an unsorted vector it will sort it and produce the right median:

{% highlight r %}
numbers <- c(36, 4, 75, 50, 45)  
median(numbers)
> [1] 45  
{% endhighlight %}

### How do we decide to use `mean` or `median`?

The `median` is defined as a robust statistic because outliers (values that are too far away from most of your measurements) have very little effect on it, while the `mean` is not robust as outliers can greatly affect it's calculation. Before deciding on which one to use, check the data you have in hand to make sure you're picking a statistic that makes sense for the data you are working with.

Calculating the `mean` of an distribution full of outliers  will most likely give you a weird value and using `median` for a distribution that has very little variance might not give you the actual center of the distribution.

## Dealing with matrices

Another common data type you'll find is the matrix. Here's how you could use a vector to create a matrix:

{% highlight r %}
m <- matrix(c(1, 2, 3, 4), nrow=2, ncol=2)
>       [,1] [,2]
> [1,]    1    3
> [2,]    2    4  
{% endhighlight %}

Here we use the `matrix` function to create a `2x2` matrix. `nrow` is the number of rows and `ncol` the number of columns, we could have called the function as `matrix(c(1, 2, 3, 4), 2, 2)` and it would also work but whenever you're calling a function that takes many parameters in *R* you're better off naming the parameters to make sure you're not making a mistake with the parameters order. It's also makes it much easier to read and understand which parameter each value is supposed to be.

Also, it's important to notice that the the matrix will be filled from the vector *by column by default*, so values are included in the matrix in columns, which is why our `1, 2, 3, 4` vector became the matrix it is now instead of:

         [,1] [,2]
    [1,]    1    2
    [2,]    3    4

If you wanted the matrix to be filled by row, you have to include the `byrow` parameter and set it to `TRUE` as in:

{% highlight r %}
m <- matrix(c(1, 2, 3, 4), nrow=2, ncol=2, byrow=TRUE)
>       [,1] [,2]
> [1,]    1    2
> [2,]    3    4  
{% endhighlight %}

You can also name the rows and columns of your matrix to make it easier to read:

{% highlight r %}
row_names <- c("Male", "Female")
col_names <- c("Right-Handed", "Left-Handed")
m <- matrix(c(43, 44, 9, 4), nrow=2, ncol=2, dimnames=list(row_names, col_names))
>        Right-Handed Left-Handed
> Male             43           9
> Female           44           4
{% endhighlight %}

To access rows, columns and specific items inside a matrix you use the `[]` operator. First, access full rows:

{% highlight r %}
m[1,]
> Right-Handed  Left-Handed
> 43            9
{% endhighlight %}

Then here's how you access a full column:

{% highlight r %}
m[,1]
> Male Female
>   43     44
{% endhighlight %}

And you can also access one specific item:

{% highlight r %}
m[2,2]
> [1] 4
{% endhighlight %}

Just like vectors and lists, indexes for matrices in *R* start at `1`.

## Factors

Factors are the way we represent categorical variables in *R*. Categorial variables are those values that instead of being simple numeric values, are states of some variable. Imagine you have patients and you would like to separate them in groups given their current health status and the status are:

* Healthy;
* Recovering;
* Sick;

These values aren't numeric, but they make sense in our data set and we would like to be able to efficiently use them in our statistics. This is such a common theme in statistics that there is this special type, `factor`, so we can use categorical variables at our programs.

While you could just use strings for these values (a vector of strings, for instance), using factors identifies this column directly as a categorical variable for *R* and this leads to better defaults when using statistical analysis and inferencing methods. Factors also use less memory and are faster to process.

Most of the time you won't be creating factors directly, you'll be instructing the code that loads your data which of your fields are factors, but let's see how you can create factors directly in *R*:

{% highlight r %}
health <- c("Healthy", "Recovering", "Sick")
health_factors <- factor(health)
> [1] "Healthy"    "Recovering" "Sick"
health_factors[1]
> [1] Healthy
> Levels: Healthy Recovering Sick
health_factors[2]
> [1] Recovering
> Levels: Healthy Recovering Sick
health_factors[3]
> [1] Sick
> Levels: Healthy Recovering Sick
{% endhighlight %}

[You can read more about the types of variables you'll find in statistical analysis here]({% post_url 2014-10-01-statistics-is-fun %}).

## Data frames

Data frames are the main data type for *R* programs, most of the data you'll be working with is either in this format or will be transformed to a data frame so you can easily work with it. Let's get started with a data frame using [Kaggle's Titanic test data](https://www.kaggle.com/c/titanic-gettingStarted):

{% highlight r %}
download.file("https://gist.githubusercontent.com/mauricio/f389c162731532e2dea5/raw/5f045d26890255c123ca02a98febf41b8bab085f/titanic.csv", destfile = "titanic.csv", method="curl")
titanic <- read.csv(
  "titanic.csv",
  colClasses=c(
    "integer", // passenger id
    "factor", // survived or not
    "factor", // passenger class
    "character", // name
    "factor", // sex
    "numeric", // age
    "integer", // number of spouse or siblings aboard
    "integer", // number of parents or children aboard
    "character", // ticket
    "numeric", // fare
    "factor", // cabin
    "factor" // port of embarkation - (C = Cherbourg; Q = Queenstown; S = Southampton)
    ))  
{% endhighlight %}

Our first step here is to download the CSV file that contains the data, *R* already has a handy download function for that, [download.file](https://stat.ethz.ch/R-manual/R-devel/library/utils/html/download.file.html), so we just use it. It's important to define the `method` parameter to `curl` or `wget` (you'll need one of them installed at your system) as the download is using `HTTPS` and the default handler for file downloads isn't capable of handling `HTTPS` connections. The file is downloaded to the `titanic.csv` file at the same directory as your current *R* session, you can use the `getwd()` function to know which directory this is and you can also call `setwd("some-path-here")` to change the session's current directory.

Now that we have the file downloaded, we can use one of the many methods to turn a file into a data frame. Since this file is a `CSV` we'll use the [read.csv](https://stat.ethz.ch/R-manual/R-devel/library/utils/html/read.table.html) function, the first parameter is the path to the file (since the file was downloaded to the current session directory, there's no need to set the full path) and we're setting only one parameterm, `colClasses`. While the `read.csv` method is smart enough to figure out the types and parse this file correctly, setting the column types gives you fine grained control to the types used and also makes parsing the file much faster as the method won't have to try to figure out the column types.

Once you have the data frame loaded, let's check it's [summary](https://stat.ethz.ch/R-manual/R-devel/library/base/html/summary.html):

{% highlight r %}
summary(titanic)
{% endhighlight %}

    PassengerId    Survived PassengerClass     Name               Sex           Age        SpouseSiblingsAboard
    Min.   :  1.0   0:549    1:216          Length:891         female:314   Min.   : 0.42   Min.   :0.000
    1st Qu.:223.5   1:342    2:184          Class :character   male  :577   1st Qu.:20.12   1st Qu.:0.000
    Median :446.0            3:491          Mode  :character                Median :28.00   Median :0.000
    Mean   :446.0                                                           Mean   :29.70   Mean   :0.523
    3rd Qu.:668.5                                                           3rd Qu.:38.00   3rd Qu.:1.000
    Max.   :891.0                                                           Max.   :80.00   Max.   :8.000
    NA's   :177
    ParentsChildrenAboard    Ticket               Fare                Cabin     Embarked
    Min.   :0.0000        Length:891         Min.   :  0.00              :687    :  2
    1st Qu.:0.0000        Class :character   1st Qu.:  7.91   B96 B98    :  4   C:168
    Median :0.0000        Mode  :character   Median : 14.45   C23 C25 C27:  4   Q: 77
    Mean   :0.3816                           Mean   : 32.20   G6         :  4   S:644
    3rd Qu.:0.0000                           3rd Qu.: 31.00   C22 C26    :  3
    Max.   :6.0000                           Max.   :512.33   D          :  3
    (Other)    :186  

The `summary` function already provides some basic information about our data set, we can see, for instance, that 342 people survived while 549 died, most people were at the third class and the average fare paid was 32.20. This is just a high level view of the data so you can start digging through the data frame yourself looking at these variables later.

Something else you can do is look right at the data itself using [head](https://stat.ethz.ch/R-manual/R-devel/library/utils/html/head.html):

{% highlight r %}
head(titanic, 3)
{% endhighlight %}

    PassengerId Survived PassengerClass                                                Name    Sex Age
    1           1        0              3                             Braund, Mr. Owen Harris   male  22
    2           2        1              1 Cumings, Mrs. John Bradley (Florence Briggs Thayer) female  38
    3           3        1              3                              Heikkinen, Miss. Laina female  26
    SpouseSiblingsAboard ParentsChildrenAboard           Ticket    Fare Cabin Embarked
    1                    1                     0        A/5 21171  7.2500              S
    2                    1                     0         PC 17599 71.2833   C85        C
    3                    0                     0 STON/O2. 3101282  7.9250              S

Or [tail](https://stat.ethz.ch/R-manual/R-devel/library/utils/html/tail.html):


{% highlight r %}
tail(titanic, 3)  
{% endhighlight %}

    PassengerId Survived PassengerClass                                     Name    Sex Age
    889         889        0              3 Johnston, Miss. Catherine Helen "Carrie" female  NA
    890         890        1              1                    Behr, Mr. Karl Howell   male  26
    891         891        0              3                      Dooley, Mr. Patrick   male  32
    SpouseSiblingsAboard ParentsChildrenAboard     Ticket  Fare Cabin Embarked
    889                    1                     2 W./C. 6607 23.45              S
    890                    0                     0     111369 30.00  C148        C
    891                    0                     0     370376  7.75              Q

These functions will print the first rows (for `head`) and last rows (for `tail`) so you can inspect a bit of your data.

And just like a matrix, you can also get specific rows, columns and everything else using the `[]` operator. For instance, here's how you access the first row:

{% highlight r %}
titanic[1,]
{% endhighlight %}

    PassengerId Survived PassengerClass                    Name  Sex Age SpouseSiblingsAboard
    1           1        0              3 Braund, Mr. Owen Harris male  22                    1
    ParentsChildrenAboard    Ticket Fare Cabin Embarked
    1                     0 A/5 21171 7.25              S

And now all items at the fourth column:

{% highlight r %}
titanic[,4]
{% endhighlight %}

    [1] "Braund, Mr. Owen Harris"
    [2] "Cumings, Mrs. John Bradley (Florence Briggs Thayer)"
    [3] "Heikkinen, Miss. Laina"
    [4] "Futrelle, Mrs. Jacques Heath (Lily May Peel)"
    [5] "Allen, Mr. William Henry"

The name of the tenth person:

{% highlight r %}
titanic[10,4]
> [1] "Nasser, Mrs. Nicholas (Adele Achem)"
{% endhighlight %}

You can use a vector for both indexes as well. For instance, if I wanted rows from 10 to 20 I could do it like:

{% highlight r %}
titanic[10:20,]
{% endhighlight %}

And you can also get all values from a single column using the `$` operator:

{% highlight r %}
titanic$Name
{% endhighlight %}

    [1] "Braund, Mr. Owen Harris"
    [2] "Cumings, Mrs. John Bradley (Florence Briggs Thayer)"
    [3] "Heikkinen, Miss. Laina"
    [4] "Futrelle, Mrs. Jacques Heath (Lily May Peel)"
    [5] "Allen, Mr. William Henry"

The [read.table](https://stat.ethz.ch/R-manual/R-devel/library/utils/html/read.table.html) docs have a full list of formats and parameters supported for reading many different file formats into data frames.

At the next part we'll part we'll see how we can subset and plot the data we have collected, stay tuned!

<script type="text/javascript"
src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML">
</script>
