---
layout: post
title: Contributing a new binding for MonoMac and making your MonoMac application updateable using Sparkle
tags:
- C#
- mono
- useful
---

When building [MonoMac](https://github.com/mono/monomac) applications you will eventually have to get your hands dirty interoperating with Cocoa/Objetive-C frameworks, one of the most common examples is updating applications. In the Mac apps world, if you're not on the app store, you probably want to allow your users to update their applications so they all can start using all the new and shiny features and the most common solution for updating Mac applications is the [Sparkle](http://sparkle.andymatuschak.org/) by [Andy Matuschak](https://github.com/andymatuschak).

It's such a hassle-free solution for udpates that it almost doesn't allow for a full blog post about it, but since we're talking about MonoMac let's also understand how we can create bindings so that we can call the Sparkle classes from our C# code.

> You will need the latest Mono MDK (not the runtime alone) and a sane build environment (Xcode command line tools) to go through all these steps

First, clone MonoMac and MacCore from Github to a common directory as in:

{% highlight bash %}
mkdir monomac-build
cd monomac-build
git clone git://github.com/mono/maccore.git
git clone git://github.com/mono/monomac.git
{% endhighlight %}

Now that you have both projects, let's build **MonoMac** and it's accessory executables:

{% highlight bash %}
cd monomac/src
make
{% endhighlight %}

This will build the **MonoMac.dll**, **parse.exe** and a bunch of other stuff we won't talk about here. The build process expects to have the **maccore** folder at the same level as the **monomac** folder so don't rename them to something else as it will probably break the build.

Once you've done this, download the **Sparkle** framework files and get it's **.h** files, they will be at the `Sparkle.framework/Headers` directory (they are `Sparkle.h`, `SUAppcast.h`, `SUAppcastItem.h`, `SUUpdater.h`, `SUVersionComparisonProtocol.h`). Copy them somewhere you can easily reference from the command line, I'd recommend placing them at the `monomac-build` directory.

Now, at the "monomac/src" directory, call `parse.exe` to generate the basic bindings from the Objective-C **.h** files:

{% highlight bash %}
mono parse.exe ../../SUAppcast.h ../../SUAppcastItem.h ../../SUUpdater.h ../../SUVersionComparisonProtocol.h 
{% endhighlight %}

This is the output you will receive:

{% highlight csharp %}
	[BaseType (typeof (NSObject))]
	interface SUAppcast {
		[Export ("fetchAppcastFromURL:")]
		void FetchAppcastFromURL (NSUrl url);

		[Export ("setDelegate:")]
		void SetDelegate ();

		[Export ("setUserAgentString:")]
		void SetUserAgentString (string userAgentString);

		[Export ("items")]
		NSArray Items ();

	}
	interface NSObject {
	}

	[BaseType (typeof (NSObject))]
	interface SUAppcastItem {
		[Export ("dict")]
		NSDictionary Dict ();

		[Export ("title")]
		string Title ();

		[Export ("versionString")]
		string VersionString ();

		[Export ("displayVersionString")]
		string DisplayVersionString ();

		[Export ("date")]
		NSDate Date ();

		[Export ("itemDescription")]
		string ItemDescription ();

		[Export ("releaseNotesURL")]
		NSUrl ReleaseNotesURL ();

		[Export ("fileURL")]
		NSUrl FileURL ();

		[Export ("DSASignature")]
		string DSASignature ();

		[Export ("minimumSystemVersion")]
		string MinimumSystemVersion ();

		[Export ("propertiesDictionary")]
		NSDictionary PropertiesDictionary ();

	}

	[BaseType (typeof (NSObject))]
	interface SUUpdater {
		[Static]
		[Export ("sharedUpdater")]
		SUUpdater SharedUpdater ();

		[Static]
		[Export ("updaterForBundle:")]
		SUUpdater UpdaterForBundle (NSBundle bundle);

		[Export ("hostBundle")]
		NSBundle HostBundle ();

		[Export ("setDelegate:")]
		void SetDelegate (NSObject delegate);

		[Export ("checkForUpdates:")]
		IBAction CheckForUpdates ();

		[Export ("checkForUpdatesInBackground")]
		void CheckForUpdatesInBackground ();

		[Export ("lastUpdateCheckDate")]
		NSDate LastUpdateCheckDate ();

		[Export ("checkForUpdateInformation")]
		void CheckForUpdateInformation ();

		[Export ("resetUpdateCycle")]
		void ResetUpdateCycle ();

		[Export ("updateInProgress")]
		bool UpdateInProgress ();

		//Detected properties
		[Export ("automaticallyChecksForUpdates")]
		bool AutomaticallyChecksForUpdates { get; set; }

		[Export ("updateCheckInterval")]
		double UpdateCheckInterval { get; set; }

		[Export ("feedURL")]
		NSUrl FeedURL { get; set; }

		[Export ("sendsSystemProfile")]
		bool SendsSystemProfile { get; set; }

		[Export ("automaticallyDownloadsUpdates")]
		bool AutomaticallyDownloadsUpdates { get; set; }

	}
	interface NSObject {
		[Export ("updaterShouldPromptForPermissionToCheckForUpdates:")]
		bool UpdaterShouldPromptForPermissionToCheckForUpdates (SUUpdater bundle);

		[Export ("updater:didFinishLoadingAppcast:")]
		void UpdaterdidFinishLoadingAppcast (SUUpdater updater, SUAppcast appcast);

		[Export ("bestValidUpdateInAppcast:forUpdater:")]
		SUAppcastItem BestValidUpdateInAppcastforUpdater (SUAppcast appcast, SUUpdater bundle);

		[Export ("updater:didFindValidUpdate:")]
		void UpdaterdidFindValidUpdate (SUUpdater updater, SUAppcastItem update);

		[Export ("updaterDidNotFindUpdate:")]
		void UpdaterDidNotFindUpdate (SUUpdater update);

		[Export ("updater:willInstallUpdate:")]
		void UpdaterwillInstallUpdate (SUUpdater updater, SUAppcastItem update);

		[Export ("updater:shouldPostponeRelaunchForUpdate:untilInvoking:")]
		bool UpdatershouldPostponeRelaunchForUpdateuntilInvoking (SUUpdater updater, SUAppcastItem update, NSInvocation invocation);

		[Export ("updaterWillRelaunchApplication:")]
		void UpdaterWillRelaunchApplication (SUUpdater updater);

		[Export ("versionComparatorForUpdater:")]
		id <SUVersionComparison> VersionComparatorForUpdater (SUUpdater updater);

		[Export ("pathToRelaunchForUpdater:")]
		string PathToRelaunchForUpdater (SUUpdater updater);

	}

	[BaseType (typeof (NSObject))]
	[Model]
	interface SUVersionComparison {
		[Abstract]
		[Export ("compareVersion:toVersion:")]
		NSComparisonResult CompareVersiontoVersion (string versionA, string versionB);

	}
{% endhighlight %}

The `parse.exe` executable parses the Objective-C header files and generates a C# representation for it's classes. It does a great job at that but it still requires some manual work to make the code more C#-like and also to remove possible misinterpretations that we'll see in a minute.

Now, at **monomac/src** create a file called **sparkle.cs** and declare a namespace on it, I'm going to use **MonoMac.Sparkle**:

{% highlight csharp %}
//
// sparkle.cs: Definitions for the Sparkle Framework
//
using System;
using MonoMac.Foundation;
using MonoMac.ObjCRuntime;
using MonoMac.AppKit;

namespace MonoMac.Sparkle {
	// contents generated from parse.exe
}
{% endhighlight %}

We just declared a bunch of namespaces we will need here and copied all contents from the `parse.exe` output to it. Once all the content is copied, let's start cleaning it up.

First, remove the empty `NSObject` reference and comment the `interface NSObject` and the end of the file. Since **Sparkle** uses an informal protocol (if you're not that used to Objective-C, it's like an anonymous interface, people are not required to fully implement it). Leaving it here serves mostly to help someone trying to implement the delegate.

Now, let's get to the first class, `SUAppcast`:

{% highlight csharp %}
[BaseType (typeof (NSObject))]
interface SUAppcast {
	[Export ("fetchAppcastFromURL:")]
	void FetchAppcastFromURL (NSUrl url);

	[Export ("setDelegate:")]
	void SetDelegate ();

	[Export ("setUserAgentString:")]
	void SetUserAgentString (string userAgentString);

	[Export ("items")]
	NSArray Items ();

}
{% endhighlight %}

Here we have two issues, first, the `SetDelegate` method did not add it's parameter (most likely because it was called **delegate** and it's a keyword in C#) and the `Items` property was translated as an `Items` method that returns an `NSArray` instead of a strongly typed `SUAppcastItem` array, let's fix it:

{% highlight csharp %}
[BaseType (typeof (NSObject))]
interface SUAppcast {
	[Export ("fetchAppcastFromURL:")]
	void FetchAppcastFromURL (NSUrl url);

	[Export ("setDelegate:")]
	void SetDelegate (NSObject delegateHandler);

	[Export ("setUserAgentString:")]
	void SetUserAgentString (string userAgentString);

	[Export ("items")]
	SUAppcastItem[] Items {[Bind("items")] get;}
}
{% endhighlight %}

Here we have added the `delegateHandler` parameter to the `SetDelegate` method (it has to be an NSObject) and we have also changed the `Items` method to be an `Items` property and return an array of `SUAppcastItem`. The `Bind` attribute is necessary because the property doesn't follow the usual **get${name}/set${name}** naming pattern, so we have to explicitly say how it's really called.

Now, off to the next one:

{% highlight csharp %}
[BaseType (typeof (NSObject))]
interface SUAppcastItem {
	[Export ("dict")]
	NSDictionary Dict ();

	[Export ("title")]
	string Title ();

	[Export ("versionString")]
	string VersionString ();

	[Export ("displayVersionString")]
	string DisplayVersionString ();

	[Export ("date")]
	NSDate Date ();

	[Export ("itemDescription")]
	string ItemDescription ();

	[Export ("releaseNotesURL")]
	NSUrl ReleaseNotesURL ();

	[Export ("fileURL")]
	NSUrl FileURL ();

	[Export ("DSASignature")]
	string DSASignature ();

	[Export ("minimumSystemVersion")]
	string MinimumSystemVersion ();

	[Export ("propertiesDictionary")]
	NSDictionary PropertiesDictionary ();

}
{% endhighlight %}

This one is mostly making all of it's properties, well, properties. Here's how it will be like:

{% highlight csharp %}
[BaseType (typeof (NSObject))]
interface SUAppcastItem {
	[Export ("dict")]
	NSDictionary Dict { [Bind("dict")] get; }

	[Export ("title")]
	string Title { [Bind("title")] get; }

	[Export ("versionString")]
	string VersionString { [Bind("versionString")] get; }

	[Export ("displayVersionString")]
	string DisplayVersionString { [Bind("displayVersionString")] get; }

	[Export ("date")]
	NSDate Date { [Bind("date")] get; }

	[Export ("itemDescription")]
	string ItemDescription { [Bind("itemDescription")] get; }

	[Export ("releaseNotesURL")]
	NSUrl ReleaseNotesURL { [Bind("releaseNotesURL")] get; }

	[Export ("fileURL")]
	NSUrl FileURL { [Bind("fileURL")] get; }

	[Export ("DSASignature")]
	string DSASignature { [Bind("DSASignature")] get; }

	[Export ("minimumSystemVersion")]
	string MinimumSystemVersion { [Bind("minimumVersion")] get; }

	[Export ("propertiesDictionary")]
	NSDictionary PropertiesDictionary { [Bind("propertiesDictionary")] get; }

}
{% endhighlight %}

And we're done on this, this one was simple, it was just making sure it looked like a C# class.

And we're off to the last one! It isn't any different from all the others, it's just making sure our final class looks like a C# class as much as possible. Here's how it looks now:

{% highlight csharp %}
[BaseType (typeof (NSObject))]
interface SUUpdater {
	[Static]
	[Export ("sharedUpdater")]
	SUUpdater SharedUpdater ();

	[Static]
	[Export ("updaterForBundle:")]
	SUUpdater UpdaterForBundle (NSBundle bundle);

	[Export ("hostBundle")]
	NSBundle HostBundle ();

	[Export ("setDelegate:")]
	void SetDelegate (NSObject delegate);

	[Export ("checkForUpdates:")]
	IBAction CheckForUpdates ();

	[Export ("checkForUpdatesInBackground")]
	void CheckForUpdatesInBackground ();

	[Export ("lastUpdateCheckDate")]
	NSDate LastUpdateCheckDate ();

	[Export ("checkForUpdateInformation")]
	void CheckForUpdateInformation ();

	[Export ("resetUpdateCycle")]
	void ResetUpdateCycle ();

	[Export ("updateInProgress")]
	bool UpdateInProgress ();

	//Detected properties
	[Export ("automaticallyChecksForUpdates")]
	bool AutomaticallyChecksForUpdates { get; set; }

	[Export ("updateCheckInterval")]
	double UpdateCheckInterval { get; set; }

	[Export ("feedURL")]
	NSUrl FeedURL { get; set; }

	[Export ("sendsSystemProfile")]
	bool SendsSystemProfile { get; set; }

	[Export ("automaticallyDownloadsUpdates")]
	bool AutomaticallyDownloadsUpdates { get; set; }
}
{% endhighlight %}

And it will become this:

{% highlight csharp %}
[BaseType (typeof (NSObject))]
interface SUUpdater {
	[Static]
	[Export ("sharedUpdater")]
	SUUpdater SharedUpdater { [Bind("sharedUpdater")] get; }

	[Static]
	[Export ("updaterForBundle:")]
	SUUpdater UpdaterForBundle (NSBundle bundle);

	[Export ("hostBundle")]
	NSBundle HostBundle { [Bind("hostBundle")] get; }

	[Export ("setDelegate:")]
	void SetDelegate (NSObject delegateHandler);

	[Export ("checkForUpdates:")]
	void CheckForUpdates ();

	[Export ("checkForUpdatesInBackground")]
	void CheckForUpdatesInBackground ();

	[Export ("lastUpdateCheckDate")]
	NSDate LastUpdateCheckDate { [Bind("lastUpdateCheckDate")] get; }

	[Export ("checkForUpdateInformation")]
	void CheckForUpdateInformation ();

	[Export ("resetUpdateCycle")]
	void ResetUpdateCycle ();

	[Export ("updateInProgress")]
	bool UpdateInProgress {[Bind("updateInProgress")] get;}

	//Detected properties
	[Export ("automaticallyChecksForUpdates")]
	bool AutomaticallyChecksForUpdates { get; set; }

	[Export ("updateCheckInterval")]
	double UpdateCheckInterval { get; set; }

	[Export ("feedURL")]
	NSUrl FeedURL { get; set; }

	[Export ("sendsSystemProfile")]
	bool SendsSystemProfile { get; set; }

	[Export ("automaticallyDownloadsUpdates")]
	bool AutomaticallyDownloadsUpdates { get; set; }
}
{% endhighlight %}

First, we make the `SharedUpdater` method become a static property (that's what it is, in fact). Then we do the same for the instance method `HostBundle`, making it an instance property, instead (anything that just gets you a value without side effects should probably become a property).

At the `SetDelegate` method, we just change the variable name to `delegateHandler` since `delegate` is a keyword in C#. Next there is the `CheckForUpdates` method that returns `IBAction` but `IBAction` means `void`in Objective-C (it's a special kind of `void` as **InterfaceBuilder** uses this to mark the method as an event handler ), so we change the return from `IBAction` to `void`.

And to wrap it all up we make `LastUpdateCheckDate` and `UpdateInProgress` properties.

Now, open the `Makefile` at **monomac/src/Makefile** and look for this piece:

{% highlight makefile linenos %}
APIS = \
	appkit.cs		\
	corewlan.cs		\
	foundation-desktop.cs 	\
	growl.cs		\
	imagekit.cs		\
	qtkit.cs		\
	pdfkit.cs		\
	webkit.cs		\
	composer.cs		\
	scriptingbridge.cs	\
	$(SHARED_APIS)
{% endhighlight %}

Just add the `sparkle.cs` file at the end:

{% highlight makefile linenos %}
APIS = \
	appkit.cs		\
	corewlan.cs		\
	foundation-desktop.cs 	\
	growl.cs		\
	imagekit.cs		\
	qtkit.cs		\
	pdfkit.cs		\
	webkit.cs		\
	composer.cs		\
	scriptingbridge.cs	\
    sparkle.cs      \
	$(SHARED_APIS)
{% endhighlight %}

Now run `make` again to rebuild the **MonoMac.dll** and now there should be a `Sparkle` directory and it should have four files:

* SUAppcast.g.cs
* SUAppcastItem.g.cs
* SUUpdater.g.cs
* SUVersionComparison.g.cs

And this new **MonoMac.dll** now contains the Sparkle framework classes!

We have finished our API beautifying, let's start using it in a sample project!

Open **MonoDevelop** and create a new **MonoMac** project, I am going to name my project as `UpdaterSample`. Do not create a directoy for the solution, leave it a the project's directory. Once you have the project ready, out of **MonoDevelop**, create a folder called **Frameworks** at the project's root. Copy the `Sparkle.framework` folder to it.

Now, open the project's options and add a [custom command at the before build phase](https://www.evernote.com/shard/s26/sh/4272e570-e0c5-468d-a9ad-9c203f22fa9b/4e654448c5e4e673228629f9fead248d) with the following command:

{% highlight bash linenos %}
rm -rf ${TargetDir}/${ProjectName}.app/Contents/Frameworks; mkdir -p ${TargetDir}/${ProjectName}.app/Contents/Frameworks; cp -a ${SolutionDir}/Frameworks/. ${TargetDir}/${ProjectName}.app/Contents/Frameworks/
{% endhighlight %}

This action copies the contens of your **Frameworks** folder to the **Contents/Frameworks** folder of your app's bundle, so you can easily drop new frameworks at this folder and they will all be copied to your bundle before building. Make sure you mark the **Run on external console** option or it isn't going to work.

Now that you have the **Sparkle** framework in place and being copied to your app, let's add the configuration keys necessary for it, first, set a build for your project (this is the information that will be used by Sparkle to check if the app version is current or not). You can do this by opening your `Info.plist` and setting it's **Build** property [as in this image](https://www.evernote.com/shard/s26/sh/7bfffb35-d4a5-4f62-8a8e-c2d7c4e19404/c2e5210197266a8e3a6db5894ee6ff1c).

Now copy the **MonoMac.dll** we built into your project folder, remove the reference to the **MonoMac.dll** that comes with the **MonoMac** ([this one](https://www.evernote.com/shard/s26/sh/b89ac790-47e2-4dc3-859f-718228b4d2ed/2a7c1a7890ca9c2deb33b66d935a0b54)) add in in **MonoDevelop** and add a reference to your own **MonoMac.dll**.

Create an `SUFeedURL` key at your `Info.plist` file and make it link to your Sparkle file, in this project I'm using:

> https://raw.github.com/mauricio/UpdaterSample/master/sparkle.xml

You can check this file and/or check Sparkle's documentation to understand more about the file format and other options.

With this, lets do a bit of coding in our project to get Sparkle to always download and always perform an update check in background when the application starts:

{% highlight csharp linenos %}
using MonoMac.Foundation;
using MonoMac.AppKit;
using MonoMac.Sparkle;

namespace UpdaterSample
{
	public partial class AppDelegate : NSApplicationDelegate
	{
		MainWindowController mainWindowController;
		
		public AppDelegate ()
		{
		}

		public override void FinishedLaunching (NSObject notification)
		{
			mainWindowController = new MainWindowController ();
			mainWindowController.Window.MakeKeyAndOrderFront (this);

			var updater = SUUpdater.SharedUpdater;
			updater.AutomaticallyDownloadsUpdates = true;
			updater.CheckForUpdatesInBackground();
		}
	}
}
{% endhighlight %}

I added the namespace to this file with the `using MonoMac.Sparkle` directive and then I just use the `SharedUpdater` available to run an update check (forcing a download before showing the screen). You can grab the zip for version [0.0.1](https://github.com/mauricio/UpdaterSample/raw/master/updater-sample-0.0.1.zip) and [0.0.2](https://github.com/mauricio/UpdaterSample/raw/master/updater-sample-0.0.2.zip) to see it in action.

At the end, we need to change our `Main.cs` file for it to load the `Sparkle.framework` native library, here's how it's done:

{% highlight csharp linenos %}
using MonoMac.AppKit;
using MonoMac.ObjCRuntime;
using System.IO;

namespace UpdaterSample
{
	class MainClass
	{
		static void Main (string[] args)
		{
			var baseAppPath = Directory.GetParent (Directory.GetParent (System.AppDomain.CurrentDomain.BaseDirectory).ToString ());
			var sparkleFrameworkPath = baseAppPath + "/Frameworks/Sparkle.framework/Sparkle";
			
			Dlfcn.dlopen (sparkleFrameworkPath, 0);

			NSApplication.Init ();
			NSApplication.Main (args);
		}
	}
}
{% endhighlight %}

With this the framework is loaded and all of our classes will execute just fine, you can do this with any framework you would like to have loaded by the app.

And with this the app should run and update fine. You can easily add new methods, set delegates and do whatever you would like to do just calling C# code and without having to worry about transforming objects from one to the other.

Now go get your hands dirty wrapping other cool Objective-C libraries. You can check the full source for this project [here](https://github.com/mauricio/UpdaterSample) and you can check my pull request with these bindings to the MonoMac project [here](https://github.com/mono/monomac/pull/77).

PS: The original idea of creating the "before build" command to copy frameworks was taken from [this blog post by Kenneth Pouncey](http://cocoa-mono.org/archives/254/growl-my-monomac-application-says/).