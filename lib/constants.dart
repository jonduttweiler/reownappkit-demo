import 'package:reown_appkit/appkit_modal.dart';

enum Environment { testing, production }

const Environment environment = Environment.production;
const PROJECT_ID = "";


final ReownAppKitModalNetworkInfo celoAlfajores = ReownAppKitModalNetworkInfo(
  name: "Celo Alfajores",
  chainId: '44787',
  chainIcon: 'ab781bbc-ccc6-418d-d32d-789b15da1f00',
  currency: 'CELO',
  rpcUrl: "https://alfajores-forno.celo-testnet.org/",
  explorerUrl: "https://alfajores.celoscan.io",
  isTestNetwork: true,
);

final ReownAppKitModalNetworkInfo celoMainnet = ReownAppKitModalNetworkInfo(
  name: "Celo Mainnet",
  chainId: '42220',
  chainIcon: 'ab781bbc-ccc6-418d-d32d-789b15da1f00',
  currency: 'CELO',
  rpcUrl: "https://forno.celo.org/",
  explorerUrl: "https://celoscan.io",
);
