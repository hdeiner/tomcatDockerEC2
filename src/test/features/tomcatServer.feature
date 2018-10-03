Feature: Tomcat Server inside an AWS EC2 Instance

  Scenario: Did the Tomcat deployment go well?
    Given I created an "AWS EC2" instance for Tomcat
    Then the instance should be running "docker-proxy" on port "8080"
    And Docker should be running image "howarddeiner/tomcattest:releaseawsoracle"
    And Docker should be redirecting port "tcp" port "8080" to port "8080"
    And "EC2" inbound port "22" should be open
    And "EC2" inbound port "8080" should be open
