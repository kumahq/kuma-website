# Control Plane Monitoring

## Available stats

API Server

| Metric                                           | Description                                                                                                                        | Alert recommendation |
|--------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|----------------------|
| api_server_http_request_duration_seconds_bucket  | long API requests might indicate CP perf problems                                                                                  |                      |
| api_server_http_requests_inflight                |                                                                                                                                    |                      |
| api_server_http_response_size_bytes_bucket       |                                                                                                                                    |                      |
| cla_cache                                        | cluster load assignment cache high miss rate might mean you need to tune the cache size or eviction policy (is that possible now?) |                      |
| cp_info                                          | having incompatible CP versions might lead to problems                                                                             |                      |
| dp_server_http_request_duration_seconds_bucket   | long DP server request duration might indicate CP/DP perf problems                                                                 |                      |
| dp_server_http_requests_inflight                 |                                                                                                                                    |                      |
| dp_server_http_response_size_bytes_bucket        |                                                                                                                                    |                      |
| go_gc_duration_seconds                           | high GC times might mean that                                                                                                      |                      |
| go_goroutines                                    |                                                                                                                                    |                      |
| go_info                                          |                                                                                                                                    |                      |
| go_memstats_alloc_bytes                          |                                                                                                                                    |                      |
| go_memstats_alloc_bytes_total                    |                                                                                                                                    |                      |
| go_memstats_buck_hash_sys_bytes                  |                                                                                                                                    |                      |
| go_memstats_frees_total                          |                                                                                                                                    |                      |
| go_memstats_gc_sys_bytes                         |                                                                                                                                    |                      |
| go_memstats_heap_alloc_bytes                     |                                                                                                                                    |                      |
| go_memstats_heap_idle_bytes                      |                                                                                                                                    |                      |
| go_memstats_heap_inuse_bytes                     |                                                                                                                                    |                      |
| go_memstats_heap_objects                         |                                                                                                                                    |                      |
| go_memstats_heap_released_bytes                  |                                                                                                                                    |                      |
| go_memstats_heap_sys_bytes                       |                                                                                                                                    |                      |
| go_memstats_last_gc_time_seconds                 |                                                                                                                                    |                      |
| go_memstats_lookups_total                        |                                                                                                                                    |                      |
| go_memstats_mallocs_total                        |                                                                                                                                    |                      |
| go_memstats_mcache_inuse_bytes                   |                                                                                                                                    |                      |
| go_memstats_mcache_sys_bytes                     |                                                                                                                                    |                      |
| go_memstats_mspan_inuse_bytes                    |                                                                                                                                    |                      |
| go_memstats_mspan_sys_bytes                      |                                                                                                                                    |                      |
| go_memstats_next_gc_bytes                        |                                                                                                                                    |                      |
| go_memstats_other_sys_bytes                      |                                                                                                                                    |                      |
| go_memstats_stack_inuse_bytes                    |                                                                                                                                    |                      |
| go_memstats_stack_sys_bytes                      |                                                                                                                                    |                      |
| go_memstats_sys_bytes                            |                                                                                                                                    |                      |
| go_threads                                       |                                                                                                                                    |                      |
| grpc_server_handled_total                        |                                                                                                                                    |                      |
| grpc_server_handling_seconds_bucket              |                                                                                                                                    |                      |
| grpc_server_msg_received_total                   |                                                                                                                                    |                      |
| grpc_server_msg_sent_total                       |                                                                                                                                    |                      |
| grpc_server_started_total                        |                                                                                                                                    |                      |
| leader                                           |                                                                                                                                    |                      |
| mads_server_http_request_duration_seconds_bucket |                                                                                                                                    |                      |
| mads_server_http_requests_inflight               |                                                                                                                                    |                      |
| mads_server_http_response_size_bytes_bucket      |                                                                                                                                    |                      |
| mesh_cache                                       |                                                                                                                                    |                      |
| process_cpu_seconds_total                        |                                                                                                                                    |                      |
| process_max_fds                                  |                                                                                                                                    |                      |
| process_open_fds                                 |                                                                                                                                    |                      |
| process_resident_memory_bytes                    |                                                                                                                                    |                      |
| process_start_time_seconds                       |                                                                                                                                    |                      |
| process_virtual_memory_bytes                     |                                                                                                                                    |                      |
| process_virtual_memory_max_bytes                 |                                                                                                                                    |                      |
| promhttp_metric_handler_requests_in_flight       |                                                                                                                                    |                      |
| promhttp_metric_handler_requests_total           |                                                                                                                                    |                      |
| store_bucket                                     |                                                                                                                                    |                      |
| store_cache                                      |                                                                                                                                    |                      |
| xds_delivery                                     |                                                                                                                                    |                      |
| xds_generation                                   |                                                                                                                                    |                      |
| xds_generation_errors                            |                                                                                                                                    |                      |
| xds_requests_received                            |                                                                                                                                    |                      |
| xds_responses_sent                               |                                                                                                                                    |                      |
| xds_streams_active                               |                                                                                                                                    |                      |
