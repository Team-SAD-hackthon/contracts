const fs = require("fs");
const hre = require("hardhat");
const inquirer = require("inquirer");
const ethers = require("ethers");

const providers = {
  '42161': new ethers.providers.JsonRpcProvider(""),
  '10': new ethers.providers.JsonRpcProvider(""),
  '137': new ethers.providers.JsonRpcProvider(""),
}

const socketAddress = {
  137: '0x38e55351Dc02320A555b137e559D71f213694c15',
  10: '0x9E9b10A58a845B864265c49Fa24bb614f585498e',
  42161: '0xa5b593ae839b3fe47983fc28da602a6deefbbc9d'
}

const chainToChainId = {
  'arbitrum': 42161,
  'optimism': 10,
  'polygon': 137
}

let userParams;
async function readFileData(path, fileName) {
  // getting the data from the file
  const dataToWrite = await fs.promises.readFile(path, (error, data) => {
    if (error) {
      console.log("Error", error);
      return null;
    }
    return data;
  });

  // Creating a new file and writing the data to it.
  const writeStream = fs.createWriteStream(`${fileName}.sol`);
  writeStream.write(dataToWrite);
  writeStream.end();
}

const deployedSatellites = {
  42161: "",
  10: "",
  137: "",
}

let deployedState = {}
let deployedController = {}
let deployedStateWriter = {}

let satelliteContracts = {
  42161: null,
  10: null,
  137: null,
}

let stateContract
let controllerContract
let stateWriterContract

async function deploySatellite(_userParams) {
  // to deploy satellite on multiple chains
  for (let i = 0; i < _userParams.chains.length; i++) {
    const chainName = _userParams.chains[i].toLowerCase();
    const chainId = chainToChainId[chainName];
    const provider = providers[chainId];
    let gasPrice;
    try {
      gasPrice = await provider.getGasPrice();
    } catch (e) {
      console.log("Error while getting gas price: ", e);
    }
    const l1Wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

    const Satellite = (
      await hre.ethers.getContractFactory("Satellite")
    ).connect(l1Wallet);
    
    const gasLimit = chainId == 42161 ? 6500000 : 2800000;
    try {
      console.log(`Deploying Satellite on ${chainName}...`);
      const satellite = await Satellite.deploy(
        socketAddress[chainId],
        "0x5fD7D0d6b91CC4787Bcb86ca47e0Bd4ea0346d34",
        chainId,
        { gasPrice: gasPrice.mul(ethers.BigNumber.from(2)), gasLimit: gasLimit }
      );
      await satellite.deployed();
      deployedSatellites[chainId] = satellite.address;
      satelliteContracts[chainId] = satellite;
      console.log(`Deployed`);
    } catch (e) {
      console.error(e)
    }
  }
}

async function deployController(_userParams) {
  // to deploy user's contract (controller)
  let chainName;
  if (_userParams.scalability === "High") {
    chainName = "polygon";
  } else if (_userParams.scalability === "Medium") {
    chainName = "arbitrum";
  } else if (_userParams.scalability === "Low") {
    chainName = "optimism";
  }
  const chainId = chainToChainId[chainName]
  const provider = providers[chainId];
  const gasPrice = await provider.getGasPrice() * 2;
  const l1Wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  try {
    console.log(`deploying controller on ${chainName}`)
    const SADVault = (
      await hre.ethers.getContractFactory('SADVault')
    ).connect(l1Wallet);
    const controller = await SADVault.deploy(socketAddress[chainId], "0x5fD7D0d6b91CC4787Bcb86ca47e0Bd4ea0346d34", { gasPrice })
    await controller.deployed();
    deployedController = {
      chainId,
      address: controller.address
    }
    controllerContract = controller

    const StateWriter = (
      await hre.ethers.getContractFactory('StateWriter')
    ).connect(l1Wallet);
    const stateWriter = await StateWriter.deploy(socketAddress[chainId], "0x5fD7D0d6b91CC4787Bcb86ca47e0Bd4ea0346d34", controller.address, { gasPrice })
    await stateWriter.deployed();
    deployedStateWriter = {
      chainId,
      address: stateWriter.address
    }
    stateWriterContract = stateWriter

    console.log("deployed")
  } catch (e) {
    console.error(e)
  }
}

async function deployState(_userParams) {
  let chainName;
  if (_userParams.security === "High") {
    chainName = "optimism";
  } else if (_userParams.security === "Medium") {
    chainName = "arbitrum";
  } else if (_userParams.security === "Low") {
    chainName = "polygon";
  }

  const chainId = chainToChainId[chainName]
  const provider = providers[chainId];
  const gasPrice = await provider.getGasPrice() * 2;
  const l1Wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  try {
    console.log(`deploying state on ${chainName}`)
    const State = (
      await hre.ethers.getContractFactory('State')
    ).connect(l1Wallet);
    const state = await State.deploy(socketAddress[chainId], "0x5fD7D0d6b91CC4787Bcb86ca47e0Bd4ea0346d34", chainId, { gasPrice })
    await state.deployed();
    deployedState = {
      chainId,
      address: state.address
    }
    stateContract = state
    console.log("deployed")
  } catch (e) {
    console.error(e)
  }
}

async function configure() {
  await Promise.all(Object.keys(satelliteContracts).map(async (chainId) => {
    const sat = deployedSatellites[chainId];
    if (!sat) return;
    try {
      console.log(`configuring satellite ${chainId}`)
      console.log(deployedState.chainId, deployedState.address)
      await sat.configureState(deployedState.chainId, deployedState.address);
      console.log(deployedController.chainId, deployedController.address)
      await sat.configureController(deployedController.chainId, deployedController.address);
    } catch (e) {
      console.error(e);
    }
  }))
}

function main() {
  inquirer
    .prompt([
      {
        type: "checkbox",
        name: "chains",
        message: "Chains you want to deploy on",
        choices: ["Polygon", "Arbitrum", "Optimism"],
      },
      {
        type: "list",
        name: "scalability",
        message: "Level of throughput and gas fees",
        choices: ["High", "Medium", "Low"],
      },
      {
        type: "list",
        name: "security",
        message: "Level of security",
        choices: ["High", "Medium", "Low"],
      },
      // {
      //   name: "protocol",
      //   message: "Enter the absolute path of your smart contract file",
      // },
      // {
      //   name: "protocolName",
      //   message: "Enter the protocol name",
      // },
      // {
      //   name: "arg",
      //   message: "Enter argument",
      // },
    ])
    .then(async (answers) => {
      userParams = answers;
      console.log("log", answers);
      // Make smart contract file
      // TODO: Enable later
      // await readFileData(answers.protocol, answers.protocolName);
      // Deploy the contract
      // deployController(answers.protocolName, answers.arg, answers);
      await deploySatellite(answers);
      await deployController(answers);
      await deployState(answers);
      console.log('deployedSatellites', deployedSatellites);
      console.log('deployedController', deployedController);
      console.log('deployedState', deployedState);
      console.log('deployedStateWriter', deployedStateWriter);
      // await configure();
    })
    .catch((error) => {
      if (error.isTtyError) {
        // Prompt couldn't be rendered in the current environment
      } else {
        // Something else went wrong
      }
    });
}

main();

1966905394394349

// /Users/salilnaik/Documents/projects/socket/plugathon/contracts/Master.sol
// 0x794a61358d6845594f94dc1db02a252b5b4814ad
