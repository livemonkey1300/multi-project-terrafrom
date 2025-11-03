terraform { 
  cloud { 
    
    organization = "gcp-live" 

    workspaces { 
      name = "testing" 
    } 
  } 
}