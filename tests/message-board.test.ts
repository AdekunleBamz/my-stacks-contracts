import { Cl, ClarityType } from "@stacks/transactions";
import { describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const address1 = accounts.get("wallet_1")!;

describe("example tests", () => {
  let content = "Hello Stacks Devs!"

  it("allows user to add a new message", () => {
    let currentBurnBlockHeight = simnet.burnBlockHeight;

    let confirmation = simnet.callPublicFn(
      "message-board",
      "add-message",
      [Cl.stringUtf8(content)],
      address1
    )

    const messageCount = simnet.getDataVar("message-board", "message-count");
      const stackTime = confirmation.events[1].data.value.value["stack-time"];
    
    expect(confirmation.result).toHaveClarityType(ClarityType.ResponseOk);
    expect(confirmation.result).toBeOk(messageCount);    
    expect(stackTime).toHaveClarityType(ClarityType.UInt);
    expect(confirmation.events[1].data.value).toBeTuple({
      author: Cl.standardPrincipal(address1),
      "author-ascii": Cl.stringAscii(address1),
      event: Cl.stringAscii("[Stacks Dev Quickstart] New Message"),
      id: messageCount,
      message: Cl.stringUtf8(content),
      time: Cl.uint(currentBurnBlockHeight),
      "stack-time": stackTime,
    });
  });

  it("rate-limits posting multiple messages in the same burn block", () => {
    // First post should succeed
    const first = simnet.callPublicFn(
      "message-board",
      "add-message",
      [Cl.stringUtf8("First")],
      address1
    );
    expect(first.result).toHaveClarityType(ClarityType.ResponseOk);

    // Second post in same burn block should fail with ERR_RATE_LIMITED (u1008)
    const second = simnet.callPublicFn(
      "message-board",
      "add-message",
      [Cl.stringUtf8("Second")],
      address1
    );
    expect(second.result).toBeErr(Cl.uint(1008));
  });

  it("allows owner to configure message fee and interval; blocks non-owner", () => {
    const nonOwnerSetFee = simnet.callPublicFn(
      "message-board",
      "set-message-fee",
      [Cl.uint(2)],
      address1
    );
    expect(nonOwnerSetFee.result).toBeErr(Cl.uint(1005));

    const setFee = simnet.callPublicFn(
      "message-board",
      "set-message-fee",
      [Cl.uint(2)],
      deployer
    );
    expect(setFee.result).toBeOk(Cl.uint(2));

    const setInterval = simnet.callPublicFn(
      "message-board",
      "set-min-post-interval",
      [Cl.uint(0)],
      deployer
    );
    expect(setInterval.result).toBeOk(Cl.uint(0));

    const post = simnet.callPublicFn(
      "message-board",
      "add-message",
      [Cl.stringUtf8("Paid post")],
      address1
    );
    expect(post.result).toHaveClarityType(ClarityType.ResponseOk);

    // withdraw should transfer 2 sbtc since fee was set to 2
    simnet.mineEmptyBurnBlocks(1);
    const withdraw = simnet.callPublicFn(
      "message-board",
      "withdraw-funds",
      [],
      deployer
    );
    expect(withdraw.result).toBeOk(Cl.bool(true));
    expect(withdraw.events[0].event).toBe("ft_transfer_event");
    expect(withdraw.events[0].data).toMatchObject({
      amount: '2',
    });
  });

  it("allows contract owner to withdraw funds", () => {
    simnet.callPublicFn(
      "message-board",
      "add-message",
      [Cl.stringUtf8(content)],
      address1
    )
    
    simnet.mineEmptyBurnBlocks(2);

    let confirmation = simnet.callPublicFn(
      "message-board",
      "withdraw-funds",
      [],
      deployer
    )
    
    expect(confirmation.result).toBeOk(Cl.bool(true));
    expect(confirmation.events[0].event).toBe("ft_transfer_event")
    expect(confirmation.events[0].data).toMatchObject({
      amount: '1',
      asset_identifier: 'SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-token::sbtc-token',
      recipient: deployer,
      sender: `${deployer}${".message-board"}`,
    })
  })
});
