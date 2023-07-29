import unittest
from pymongo import MongoClient
from kubernetes import client, config
import base64

class MongoDBSanityTest(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        """Set up once before running all tests"""
        cls.password = cls.get_mongodb_password()
        cls.client = MongoClient('localhost', 27017,
                                 username='root',
                                 password=cls.password,
                                 authSource='admin')
        cls.db = cls.client['testdb']
        cls.testcollection = cls.db['testcollection']

    @classmethod
    def tearDownClass(cls):
        """Tear down once after running all tests"""
        cls.client.close()

    @staticmethod
    def get_mongodb_password():
        config.load_kube_config()
        v1 = client.CoreV1Api()
        secret = v1.read_namespaced_secret(name="mongodb", namespace="default")

        encoded_password = secret.data["mongodb-root-password"]
        if isinstance(encoded_password, bytes):
            decoded_password = base64.b64decode(encoded_password).decode('utf-8')
        else:
            decoded_password = base64.b64decode(encoded_password.encode('utf-8')).decode('utf-8')

        client.ApiClient().close()

        return decoded_password

    def test_mongo_insert_and_find(self):
        """Test inserting and fetching a document"""
        print("Testing: Inserting and fetching a document from MongoDB...")

        self.testcollection.insert_one({"name": "Alice", "age": 25, "profession": "Engineer"})
        alice_data = self.testcollection.find_one({"name": "Alice"})

        self.assertIsNotNone(alice_data, "Failed: Document was not inserted correctly.")
        self.assertEqual(alice_data['name'], 'Alice', "Failed: Name mismatch.")
        self.assertEqual(alice_data['age'], 25, "Failed: Age mismatch.")
        self.assertEqual(alice_data['profession'], 'Engineer', "Failed: Profession mismatch.")

        print("Passed: Document was inserted and fetched successfully.")

    def tearDown(self):
        """Cleanup after each test method"""
        self.testcollection.delete_one({"name": "Alice"})

if __name__ == "__main__":
    unittest.main()

