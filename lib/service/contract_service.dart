import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dapp/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

final _contractProvider = ChangeNotifierProvider((ref) => ContractService());

class ContractService extends ChangeNotifier {
  static AlwaysAliveProviderBase<ContractService> get provider =>
      _contractProvider;
  bool loading = true;

  // It allows us to establish connection with ETH
  late final Web3Client _web3client;
  late final DeployedContract _deployedContract;
  // Address of our deployed smart contract on ETH
  late final EthereumAddress _contractAddress;
  // Function Defined in our Smart Contract to increment Count
  late final ContractFunction _increment;
  // Function Defined in our Smart Contract to get Count
  late final ContractFunction _count;
  late final String _abiCode;
  // credentials of deployer
  late final Credentials _credentials;

  int count = 0;

  ContractService() {
    _initWeb3();
  }

  Future<void> _initWeb3() async {
    // Web3Client initilized
    _web3client = Web3Client(Constants.RPC_URL, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(Constants.WS_URL).cast<String>();
    });
    await _getAbi();
    await _getCredentials();
    await _getDeployedContract();
  }

  Future<void> _getAbi() async {
    // loads json file
    String abiFile = await rootBundle.loadString('src/contracts/Counter.json');

    final abiJSON = jsonDecode(abiFile);
    _abiCode = jsonEncode(abiJSON['abi']);

    // get contact address from abiJSON
    _contractAddress =
        EthereumAddress.fromHex(abiJSON['networks']['5777']['address']);
  }

  Future<void> _getCredentials() async {
    _credentials = EthPrivateKey.fromHex(Constants.PRIVATE_KEY);
  }

  Future<void> _getDeployedContract() async {
    _deployedContract = DeployedContract(
        ContractAbi.fromJson(_abiCode, "Counter"), _contractAddress);

    _increment = _deployedContract.function("increment");
    _count = _deployedContract.function("count");

    getCount();
  }

  getCount() async {
    final num = await _web3client
        .call(contract: _deployedContract, function: _count, params: []);

    count = int.parse(num.first.toString());
    loading = false;
    notifyListeners();
  }

  incrementCount({int countValue = 1}) async {
    loading = true;
    notifyListeners();
    await _web3client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _deployedContract,
            function: _increment,
            parameters: [BigInt.from(countValue)]));
    getCount();
  }
}
