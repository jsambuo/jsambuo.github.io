---
layout: post
title:  "My experience with GCP"
date:   2018-01-15 11:12:20
---
I’ve been working with Google Cloud Platform (GCP) for a side project team for the past year, and there has been ups and downs. Let me share with you some of my experience.

At the time of this writing, Google Cloud Functions is still in beta. When I started working on the side project, my group and I decided to use GCP and build using a "serverless" style. We didn’t exactly know what that meant, but we wanted low cost to start. We choose GCP over AWS because we heard it was cheaper in some ways, to keep within the Google ecosystem, and just to try and learn something different.

I wanted to build using Google Cloud Functions, as I felt that style of cloud computing was superior compared to App Engine. Having 100% utilization should save us money, especially in the beginning because we are not using them much, but even if we scale to millions of users. The free tier of two million free invocations should keep us going for a really long time throughout development.

At the beginning, it was pretty nice. Adding an endpoint was quick and easy, and there were many examples to help with integrating with Google Cloud Storage and Datastore. Over time, we started facing more and more hurdles. I’ve learned now that Google Cloud Functions is in beta, and that means not everything works nicely together with Functions. I also now believe that Functions is currently designed for smaller events and triggers, and anything slightly more complex may be out of scope. With that in mind, here are some of the issues we faced:

### No RESTful APIs

A Function with an HTTP trigger is code that runs when an endpoint is called. If you want GET to do something different than a POST, you’ll have to write an if statement. If you want to use path parameters and have sub-paths, you’ll have to parse those yourself and put them in another conditional. The tester always uses POST, and there is no way to change that. It seems like with Functions, we can only make RPC style APIs. One unfortunate consequence is we were using OpenAPI specs to document our APIs, and they have a slightly better UI when your parameters is something other than a JSON body. With few hesitations, we moved forward with this in mind, making all of our calls use POST, and using only the JSON body for parameters.

![Google Cloud Function Tester]({{ "/assets/GCP_Functions_Tester.png" | absolute_url }})

### Local development

When developing APIs, we wanted to have a local environment setup so we don’t have to use internet each time. With the gcloud SDK, there is a functions emulator, which is helpful. Each time before development, I need to run `functions start` to start it. I’m also using Datastore, so I have to that up first before starting `functions` so `functions` can pick up the environment variable to use Datastore locally. To start Datastore, I use `gcloud beta emulators datastore start`. I also need to run `$(gcloud beta emulators datastore env-init)` to set the environment variables. The last thing I’m using is Google Cloud Storage. I currently don’t see a way to use my local file storage, so everything currently goes to the cloud bucket.

It’s a bit cumbersome to use. To start up, I placed the steps on the README.md, and I need to refer to it when developing. I’m trying to make npm run scripts for these, but it’s tricky to find a way to wait for the datastore to completely start up before starting functions. Also, the functions server will sometimes stop if your function crashes, so you’ll have to restart it manually. 

Unit testing is tricky, but can be done. I’m using a combination of modules including `assert`, `node-mocks-http`, `sinon`, and `mock-require` to intercept and stub out calls, especially for Datastore. The actual code is simply imported and the function gets called, passing in the fake request, and asserting on the response. I use `npm run test` to start the test. It runs using `mocha`. It also uses `jshint` for code linting, and `nyc` for code coverage.

### Common code

We needed a structure for development. One option was to store each function in it’s own folder. We went with grouping related functions together, so some code can be shared. We also wrote custom scripts to help work with this structure, including installing and deploying all functions locally and to GCP. One additional tricky part is sharing code across groups. The difficult part is you cannot easily upload files outside of a folder. We’d either have to upload everything for each function, or somehow get the common code uploaded with the function. We ended up using `npm` to grab the common code as a local package. When we deploy, we now also upload the `node_modules` folder so the dependencies can be accessed. The uploaded files becomes about 20MB. We cannot actually publish the common project as a private dependency without paying, and we didn’t want to make it public since it contained things like authentication logic. Symlinks also didn’t work well with neither `git` nor `gcloud`. This seems like a decent tradeoff for now.

As I’m writing this, I’m realizing that maybe we can write the functions in a way where we can run it as functions, but we can get the benefits of a cohesive development experience (and potentially make it express compatible), without actually using App Engine. I’ll have to try that out.

### Auth0 integration

Integration with Auth0 was slightly tricky. Many of their tutorials was referencing `express-jwt` to work with JSON Web Tokens (jwt). Since we were not using `express`, I had to find and learn how to use `jsonwebtoken` to grab and parse the token myself. Looking at `express-jwt` showed me how to [parse and validate the token](https://github.com/auth0/express-jwt/blob/master/lib/index.js#L55-L61). This then becomes one of the common functions that every other function may use.

### Endpoints / API Gateway

It would be nice if there was something that can be placed in front of the functions and handle authentication / authorization for us. I believe Google Cloud Endpoints or API Gateway would’ve been able to handle that for us. Unfortunately, it seems that Cloud Endpoints primarily works for App Engine. I haven’t checked to see if we can use API Gateway, but for now, it would be nice if we can stay on Google’s infrastructure. 

### Cost

This one is actually a plus for Cloud Functions. We just got charged for app instance flex hours, which we didn’t know was running. About 1000 core hours costed us $54, and 3000 hours costed over $150, so I’m thinking a few instances were on. (Luckily we were given $300 credit as part of the trial.) We haven’t been charged for Cloud Functions, and 850 Gb-hours of Cloud Storage was $0.03. This seems like a major plus for using functions.

### Final thoughts

We’re still evaluating different ways of development to see what works best. It’s still early in the project, so we can switch to AWS if it suits our needs better. I imagine Cloud Functions will mature and become much nicer to use in the future. For now, we’ll do what we need to get things done. Learn to use `gcloud` effectively, and it will pay off in the long run. It’s very easy to turn on services and forget to turn them off. Be careful with that, it can become very expensive very fast.