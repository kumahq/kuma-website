# complete code
import yaml

def update_health_probes_config(file_path):
    with open(file_path, 'r') as f:
        config = yaml.safe_load(f)
    
    config['health_probes']['liveness_probe']['failure_threshold'] = 3
    config['health_probes']['liveness_probe']['initial_delay_seconds'] = 30
    config['health_probes']['liveness_probe']['period_seconds'] = 20
    config['health_probes']['liveness_probe']['success_threshold'] = 1
    config['health_probes']['liveness_probe']['tcp_socket']['port'] = 8080
    config['health_probes']['liveness_probe']['timeout_seconds'] = 5
    
    config['health_probes']['readiness_probe']['failure_threshold'] = 2
    config['health_probes']['readiness_probe']['http_get']['path'] = '/ready'
    config['health_probes']['readiness_probe']['http_get']['port'] = 8080
    config['health_probes']['readiness_probe']['initial_delay_seconds'] = 15
    config['health_probes']['readiness_probe']['period_seconds'] = 10
    config['health_probes']['readiness_probe']['success_threshold'] = 3
    config['health_probes']['readiness_probe']['timeout_seconds'] = 5
    
    config['health_probes']['startup_probe']['failure_threshold'] = 5
    config['health_probes']['startup_probe']['http_get']['path'] = '/health/startup'
    config['health_probes']['startup_probe']['http_get']['port'] = 8080
    config['health_probes']['startup_probe']['period_seconds'] = 15
    config['health_probes']['startup_probe']['timeout_seconds'] = 5
    
    with open(file_path, 'w') as f:
        yaml.dump(config, f, default_flow_style=False)

def update_kuma_sidecar_config(file_path):
    with open(file_path, 'r') as f:
        config = yaml.safe_load(f)
    
    config['kuma_sidecar_config']['health']['ready'] = True
    config['kuma_sidecar_config']['probes']['endpoints'] = [
        {'inbound_path': '/health?plugins', 'inbound_port': 8282, 'path': '/8282/health?plugins'},
        {'inbound_path': '/ready', 'inbound_port': 8080, 'path': '/8080/ready'},
        {'inbound_path': '/health/startup', 'inbound_port': 8080, 'path': '/8080/health/startup'}
    ]
    config['kuma_sidecar_config']['port'] = 9000
    
    with open(file_path, 'w') as f:
        yaml.dump(config, f, default_flow_style=False)

def add_documentation_section(file_path):
    with open(file_path, 'r') as f:
        config = yaml.safe_load(f)
    
    config['documentation'] = {
        'title': 'Health Probes Configuration',
        'description': 'This section explains the health probes configuration used in the app container.'
    }
    
    with open(file_path, 'w') as f:
        yaml.dump(config, f, default_flow_style=False)

def main():
    update_health_probes_config('app/_data/docs_nav_kuma_2.5.x.yml')
    update_kuma_sidecar_config('app/_data/kuma_sidecar_config.yml')
    add_documentation_section('app/_data/docs_nav_kuma_2.5.x.yml')

if __name__ == '__main__':
    main()