terraform { 
  cloud { 
    
    organization = "amp-services-limited" 

    workspaces { 
      name = "aws-ccoe-pilot-gha-poc" 
    } 
  } 
}