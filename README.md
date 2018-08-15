[![Build Status](https://travis-ci.com/scottberke/anagram-search.svg?token=epmpx7xuxypz89JRjqcG&branch=master)](https://travis-ci.com/scottberke/anagram-search)
# Anagram Search

## Description
This application provides fast searches for anagrams. Anagrams are ingested when the application loads and provides the following endpoints.
Three endpoints currently exist:
 1. POST [`/words.json`](#words)
 2. GET [`/anagrams/:word.json`](#anagrams)
 3. DELETE [`/words/:word.json`](#words)
 4. DELETE [`/words.json`](#words)
 5. GET [`/stats.json`](#stats)

These endpoints are documented below with example usage.

## Notes
Initially, I wrote this up using Rails API but I started to think that since the project specified building an API allowing for **fast** searches, Rails most likely added unnecessary overhead. I had some time yesterday, so I went back and wrote up two more versions of the API, one with Ruby/Sinatra and another in Go (I've just recently started playing around with Go). I did some benchmark testing using Apache ab and, to no surprise, the Go version is the fastest. The Go version was also substantially faster when it came to ingesting the dictionary file.

To run tests against each server, I ran the server for the corresponding version and executed:
```bash
$ ab -k -c 10 -n 10000 -v 4 $MY_REQUEST http://localhost:3000/anagrams/read.json
# Rails required http://0.0.0.0:3000/anagrams/read.json for some reason
```
This corresponded to 10 concurrent processes serving a total of 10000 requests.
The interesting stats for each API are what follows below. It's noteworthy that Rails was the slowest in terms of time per request, number of requests per second and was the only API that had any failed requests. My guess is that this is due to Apache ab server requests faster than it could handle.
I was able to drastically improve time per request for both Rails and Sinatra by disabling the stdout logging. In the end, the Go API is the clear winner when it comes to fast concurrent searches.
#### GO:
```
Concurrency Level:      10
Time taken for tests:   2.770 seconds
Complete requests:      10000
Failed requests:        0
Requests per second:    3609.81 [#/sec] (mean)
Time per request:       2.770 [ms] (mean)
Time per request:       0.277 [ms] (mean, across all concurrent requests)
```
***
#### Ruby On Rails API
```
Concurrency Level:      10
Time taken for tests:   19.992 seconds
Complete requests:      10000
Failed requests:        1453
Requests per second:    500.21 [#/sec] (mean)
Time per request:       19.992 [ms] (mean)
Time per request:       1.999 [ms] (mean, across all concurrent requests)
```
***
#### Ruby w/ Sinatra
```
Concurrency Level:      10
Time taken for tests:   6.834 seconds
Complete requests:      10000
Failed requests:        0
Requests per second:    1463.37 [#/sec] (mean)
Time per request:       6.834 [ms] (mean)
Time per request:       0.683 [ms] (mean, across all concurrent requests)
```
***
Other aspects of the project worth noting:
- I chose to process the dictionary file on server load and store the anagrams in memory. I chose to do this to enable fast lookups with the tradeoff being that any anagrams added via the create endpoint wouldn't be persisted unless I updated that endpoint to also write them to the txt file. This could also be an issue if there were multiple instances of the server running due to anagram creation endpoint causing the instances to become out of sync. The size of the dictionary in memory was fairly trivial and shouldn't cause any issues.
- Ingesting the file into memory should be around `O(n log n * m )` where `n` is the length of the longest word and `m` is the number of words in the txt file
- Getting anagrams should be around `O(n log n)` where `n` is the length of the longest word. This is due to the hash lookups taking place in constant time and the sort needing to take place to get the key. There's added complexity for the set difference being performed on `[all anagrams for search word] - [search word]` but that something along the lines of `O(n)` where `n` is the length of the array of `[all anagrams for search word]` (this complexity is what I understand after looking at the Ruby source code and seeing that its O(x+y) to do set difference with x and y being the length of the two arrays - in our case [search word] array length is constant or 1)
## To Run Locally
Execute:
```bash
  $ git clone https://github.com/scottberke/anagram-search.git
  $ ruby anagram_search.rb
```

## Endpoints

### Anagrams
#### GET /anagrams/:words.json
Used to get anagrams for a word. Consumes a word and returns JSON of matching anagrams.

##### Request
```bash
curl -X GET \
  http://localhost:3000/anagrams/read.json \
```
##### Response 200 OK
```json
{
    "anagrams": [
        "ared",
        "daer",
        "dare",
        "dear"
    ]
}
```

### Words
#### POST /words.json
Use to add words to the anagrams dictionary. Takes a JSON array of English-language words.

##### Request
```bash
curl -X POST \
  http://localhost:3000/words.json \
  -H 'Content-Type: application/json' \
  -d '{ "words": ["read", "dear", "dare"] }'
```
##### Response 201 Created
```json

```

#### DELETE /words.json
Use to delete all contents in the dictionary.

##### Request
```bash
curl -X DELETE \
  http://localhost:3000/words.json \
```
##### Response 204 No Content
```json

```

#### DELETE /words/:word.json
Use to delete a single word from the dictionary.

##### Request
```bash
curl -X DELETE \
  http://localhost:3000/words/read.json \
```
##### Response 204 No Content
```json

```

### Stats
#### GET /stats.json
Used to obtain stats for the words in the dictionary.

##### Request
```bash
curl -X GET \
  http://localhost:8080/stats.json \
```
##### Response 200 OK
```json
{
    "stats": {
        "min": 1,
        "max": 24,
        "median": 0,
        "average": 9.56,
        "words_count": 235886
    }
}
```
