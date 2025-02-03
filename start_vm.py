import google.auth
from googleapiclient import discovery

def start_vm(request):
    credentials, project = google.auth.default()
    service = discovery.build('compute', 'v1', credentials=credentials)
    instance = 'name-vm'
    zone = 'zone'
    
    request = service.instances().start(project=project, zone=zone, instance=instance)
    response = request.execute()
    
    return f'Starting VM: {instance}'
