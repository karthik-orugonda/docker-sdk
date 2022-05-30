import yaml
import logging
import os.path

class YamlParser:

    def __init__(self):
        logging.info('[YamlParser] YamlParser constructor')

    @classmethod
    def get_deploy_file_data(self):
        return self.parse("configs/docker/deployment/{}/project.yml".format(os.environ['SPRYKER_PROJECT_NAME']))

    @classmethod
    def parse(self, yaml_file_to_read):
        logging.info('[YamlParser] Reading yml file - {}'.format(yaml_file_to_read))

        if not os.path.exists(yaml_file_to_read):
            logging.info('[YamlParser] File with the name "{}" doesn\'t exist'.format(yaml_file_to_read))
            return None

        with open(yaml_file_to_read, "r") as stream:
            try:
                return yaml.safe_load(stream)
            except yaml.YAMLError as e:
                logging.error('An error occurred:' + e)
                return None

    @classmethod
    def get_applications(self):
        logging.info('[YamlParser] Get the list of defined applications and endpoints per tenant')
        deploy_file_data = self.get_deploy_file_data()

        applications = {}
        for group_key, group_data in deploy_file_data['groups'].items():
            for application_key,application_data in group_data['applications'].items():
                for endpoint_key,endpoint_data in application_data['endpoints'].items():
                    if 'store' not in endpoint_data:
                        continue

                    if endpoint_data['store'] not in applications:
                        applications[endpoint_data['store']] = []

                    endpoints = {
                        'type': application_data['application'],
                        'url': 'https://' + endpoint_key
                    }
                    applications[endpoint_data['store']].append(endpoints)

        return applications

    @classmethod
    def get_stores(self):
        deploy_file_data = self.get_deploy_file_data()

        stores = []
        for region_name, region_data in deploy_file_data['regions'].items():
            for store_key, store_data in  region_data['stores'].items():
                stores.append(store_key)

        return stores