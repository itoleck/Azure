param myObject object = {
  tag1: 'main1'
  tag2: 'main2'
  tag3: 'main3'
  tag4: 'main4'
  tag5: 'main5'
}

//TODO create a resource based on the object

output myObjectOutput string = string(json(string(myObject)))
