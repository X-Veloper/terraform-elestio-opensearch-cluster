// Javascript example
const { Client } = require('@opensearch-project/opensearch/.');

const client = new Client({
  auth: {
    username: 'root',
    password: '*****',
  },
  nodes: [
    'https://opensearch-1-cname.vm.elestio.app:19200',
    'https://opensearch-2-cname.vm.elestio.app:19200',
  ],
  nodeSelector: 'round-robin',
});

client
  .search({
    index: 'my-index',
    body: {
      query: {
        match: { title: 'OpenSearch' },
      },
    },
  })
  .then((response) => {
    console.log(response.hits.hits);
  })
  .catch((error) => {
    console.log(error);
  });
