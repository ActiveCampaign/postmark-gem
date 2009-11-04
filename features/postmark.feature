Feature: sending emails through Postmark API
  In order to communicate effectively with the world
  My application should be able to deliver emails through the postmark API

  Background: 
    Given the service listens to "http://postmarkapp.local"
    And I have an account with api key "mykey"
    
  Scenario: Sending simple email
    Given I send the following email:
      | From    | leonard@bigbangtheory.com |
      | To      | sheldon@bigbangtheory.com |
      | Subject | About that last night     |
      | Body    | Sorry for not coming      |
    Then the service should receive an email on behalf of "mykey" for "sheldon@bigbangtheory.com"
