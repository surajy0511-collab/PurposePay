"""Generates the architecture / contract / workflow / comparison diagrams used in the report and deck."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

INDIGO, TEAL, AMBER, RED, GREY, INK, PALE, PALE2 = "#2B3A8C", "#0E7C66", "#B7791F", "#B42318", "#6B7280", "#101828", "#E8EBF7", "#E4F4EF"
plt.rcParams["font.family"] = "DejaVu Sans"

def box(ax, x, y, w, h, text, fc=PALE, ec=INDIGO, fs=10, bold=False, tc=INK, lw=1.4, r=0.012):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle=f"round,pad=0.004,rounding_size={r}", fc=fc, ec=ec, lw=lw))
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center", fontsize=fs, color=tc, fontweight="bold" if bold else "normal", linespacing=1.35)

def arrow(ax, p, q, text="", color=INK, style="-|>", rad=0.0, fs=8.5, off=(0, 0.012), ls="-"):
    ax.add_patch(FancyArrowPatch(p, q, arrowstyle=style, mutation_scale=13, lw=1.5, color=color, connectionstyle=f"arc3,rad={rad}", linestyle=ls))
    if text:
        ax.text((p[0] + q[0]) / 2 + off[0], (p[1] + q[1]) / 2 + off[1], text, ha="center", va="bottom", fontsize=fs, color=color)

def canvas(w=13, h=7.2):
    fig, ax = plt.subplots(figsize=(w, h)); ax.set_xlim(0, 1); ax.set_ylim(0, 1); ax.axis("off"); return fig, ax

# ---------------------------------------------------------------- 1. architecture
fig, ax = canvas()
ax.text(0.5, 0.965, "PurposePay system architecture (as implemented in the PoC)", ha="center", fontsize=15, fontweight="bold", color=INK)
ax.add_patch(FancyBboxPatch((0.02, 0.62), 0.96, 0.28, boxstyle="round,pad=0.004,rounding_size=0.015", fc="#F6F7FB", ec=GREY, lw=1, ls="--"))
ax.text(0.03, 0.865, "Participants: browser DApp (HTML + JavaScript + ethers.js v6)", fontsize=10, color=GREY, fontweight="bold")
people = ["Central bank\n(Issuer)", "KYC registrar\n(State agency)", "Department\n(Scheme owner)", "Compliance\nofficer", "Beneficiary", "Merchant"]
for i, t in enumerate(people):
    box(ax, 0.035 + i * 0.157, 0.70, 0.14, 0.12, t, fs=9.5)
ax.text(0.5, 0.645, "Each persona signs with its own account; the DApp pre-checks the rules and decodes contract errors", ha="center", fontsize=9, color=GREY)
arrow(ax, (0.5, 0.62), (0.5, 0.545), "JSON-RPC: eth_call, eth_sendTransaction, event logs", color=INDIGO, off=(0.16, -0.004))
ax.add_patch(FancyBboxPatch((0.02, 0.215), 0.96, 0.33, boxstyle="round,pad=0.004,rounding_size=0.015", fc="#EEF8F5", ec=TEAL, lw=1.5))
ax.text(0.03, 0.515, "Ledger: EVM chain   |   events (Allocated, Spent, Redeemed, Reclaimed) form the shared audit trail", fontsize=10, color=TEAL, fontweight="bold")
ax.text(0.03, 0.487, "PoC: local Hardhat node (chain 31337).  Production target: permissioned EVM network, e.g. Hyperledger Besu", fontsize=8.8, color=TEAL)
box(ax, 0.05, 0.25, 0.26, 0.2, "ParticipantRegistry\nbeneficiaries (ID hash only)\nmerchants + category mask\nfreeze / suspend", fc="white", ec=TEAL, fs=9.2)
box(ax, 0.37, 0.25, 0.26, 0.2, "WelfareVault\nschemes, funding, allocation\nspend() rule engine\nexpiry, reclaim, pause", fc="white", ec=AMBER, fs=9.2, bold=False)
box(ax, 0.69, 0.25, 0.26, 0.2, "RupeeToken\nsimulated e-rupee (2 decimals)\nissue (central bank only)\nredeem (burn + bank event)", fc="white", ec=INDIGO, fs=9.2)
arrow(ax, (0.37, 0.36), (0.31, 0.36), "reads rules", color=TEAL, off=(0, 0.012))
arrow(ax, (0.63, 0.36), (0.69, 0.36), "moves tokens", color=INDIGO, off=(0, 0.012))
ax.add_patch(FancyBboxPatch((0.02, 0.02), 0.96, 0.15, boxstyle="round,pad=0.004,rounding_size=0.015", fc="#FFF7E6", ec=AMBER, lw=1.2, ls="--"))
ax.text(0.03, 0.14, "Off-chain systems (simulated by reference strings in the PoC)", fontsize=9.5, color=AMBER, fontweight="bold")
for t, x in [("Identity / KYC system\nsalted hash goes on-chain", 0.05), ("Merchant billing system\ninvoice hash goes on-chain", 0.37), ("Bank adapter\nlistens to Redeemed events", 0.69)]:
    box(ax, x, 0.035, 0.26, 0.07, t, fc="white", ec=AMBER, fs=8.8)
arrow(ax, (0.18, 0.17), (0.18, 0.25), "", color=AMBER, ls="--")
arrow(ax, (0.50, 0.17), (0.50, 0.25), "", color=AMBER, ls="--")
arrow(ax, (0.82, 0.25), (0.82, 0.17), "", color=AMBER, ls="--")
fig.savefig("diagrams/architecture.png", dpi=170, bbox_inches="tight", facecolor="white"); plt.close(fig)

# ---------------------------------------------------------------- 2. contract architecture
fig, ax = canvas(13, 6.6)
ax.text(0.5, 0.96, "Smart contract architecture and access control", ha="center", fontsize=15, fontweight="bold")
def card(x, y, w, h, title, roles, funcs, col):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.004,rounding_size=0.012", fc="white", ec=col, lw=1.8))
    ax.add_patch(FancyBboxPatch((x, y + h - 0.085), w, 0.085, boxstyle="round,pad=0.004,rounding_size=0.012", fc=col, ec=col))
    ax.text(x + w / 2, y + h - 0.043, title, ha="center", va="center", color="white", fontsize=11.5, fontweight="bold")
    ax.text(x + 0.012, y + h - 0.105, "Roles: " + roles, fontsize=8.4, color=GREY, va="top")
    ax.text(x + 0.012, y + h - 0.175, funcs, fontsize=8.6, va="top", linespacing=1.55, family="DejaVu Sans Mono")
card(0.02, 0.10, 0.28, 0.78, "ParticipantRegistry", "REGISTRAR, COMPLIANCE", "registerBeneficiary(w, idHash)\nregisterMerchant(w, name,\n  categoryMask, licenceHash)\nupdateMerchantCategories()\nsetBeneficiaryFrozen()\n   [COMPLIANCE]\nsetMerchantSuspended()\n   [COMPLIANCE]\nisBeneficiaryActive(w)\nisMerchantEligible(m, cat)\n\nGuards: one identity hash\n-> one wallet; mask != 0", TEAL)
card(0.36, 0.10, 0.28, 0.78, "WelfareVault", "SCHEME_ADMIN, COMPLIANCE", "createScheme(name, cat,\n  start, expiry, cap)\nfundScheme(id, amt)\nallocate / allocateBatch\n  (max 100 per call)\nrevokeAllocation\nwithdrawPool\nspend(id, merchant, amt,\n  invoiceRef) [beneficiary]\nreclaimExpired(id, ben)\n   [anyone, after expiry]\nsetSchemePaused()\n   [COMPLIANCE]\nisSolvent()", AMBER)
card(0.70, 0.10, 0.28, 0.78, "RupeeToken (ERC-20)", "ISSUER, DEFAULT_ADMIN", "issue(to, amt, ledgerRef)\n   [ISSUER only]\nredeem(amt, bankRef)\ndecimals() = 2\n\nEvents\n  Issued, Redeemed,\n  Transfer\n\nErrors\n  ZeroAddress, ZeroAmount", INDIGO)
arrow(ax, (0.36, 0.60), (0.30, 0.60), "", color=INK)
ax.text(0.33, 0.625, "reads", ha="center", fontsize=8.5)
arrow(ax, (0.64, 0.60), (0.70, 0.60), "", color=INK)
ax.text(0.67, 0.625, "pays", ha="center", fontsize=8.5)
ax.text(0.5, 0.035, "Invariant checked by tests and isSolvent():  token.balanceOf(vault) >= sum over schemes of (pool + outstanding)", ha="center", fontsize=9.5, color=TEAL, fontweight="bold")
fig.savefig("diagrams/contracts.png", dpi=170, bbox_inches="tight", facecolor="white"); plt.close(fig)

# ---------------------------------------------------------------- 3. workflow
fig, ax = canvas(13, 6.2)
ax.text(0.5, 0.96, "End-to-end transaction lifecycle", ha="center", fontsize=15, fontweight="bold")
steps = [("1 Issue", "Central bank\nissue()", INDIGO), ("2 Register", "Registrar\nregisterBeneficiary\nregisterMerchant", TEAL), ("3 Fund", "Department\ncreateScheme\nfundScheme", INDIGO), ("4 Allocate", "Department\nallocate /\nallocateBatch", INDIGO), ("5 Spend", "Beneficiary\nspend()", AMBER), ("6 Redeem", "Merchant\nredeem()", TEAL), ("7 Reclaim", "Anyone, after expiry\nreclaimExpired()", INDIGO)]
n = len(steps); w = 0.115; gap = (0.96 - n * w) / (n - 1)
for i, (t, d, c) in enumerate(steps):
    x = 0.02 + i * (w + gap)
    ax.add_patch(FancyBboxPatch((x, 0.62), w, 0.2, boxstyle="round,pad=0.004,rounding_size=0.012", fc=c, ec=c))
    ax.text(x + w / 2, 0.76, t, ha="center", color="white", fontsize=11, fontweight="bold")
    ax.text(x + w / 2, 0.685, d, ha="center", va="center", color="white", fontsize=8, linespacing=1.3)
    if i < n - 1: arrow(ax, (x + w + 0.002, 0.72), (x + w + gap - 0.002, 0.72), color=INK)
ax.add_patch(FancyBboxPatch((0.02, 0.10), 0.96, 0.4, boxstyle="round,pad=0.004,rounding_size=0.012", fc="#FFF7E6", ec=AMBER, lw=1.4))
ax.text(0.03, 0.47, "spend() runs these checks in one atomic transaction; any failure reverts and no money moves", fontsize=10.5, fontweight="bold", color=AMBER)
checks = ["scheme exists and is not paused", "current time is inside [start, expiry)", "amount > 0", "caller is a registered, un-frozen beneficiary",
          "merchant is registered, active and approved for the category", "amount <= per-payment cap (if set)", "amount <= remaining entitlement"]
for i, c in enumerate(checks):
    col = i // 4; row = i % 4
    ax.text(0.04 + col * 0.48, 0.395 - row * 0.075, f"{i + 1}.  {c}", fontsize=9.6, color=INK)
ax.text(0.04, 0.115, "Then: entitlement -= amount, outstanding -= amount, tokens transferred to merchant, Spent event (with invoice hash) emitted", fontsize=9.3, color=INDIGO)
fig.savefig("diagrams/workflow.png", dpi=170, bbox_inches="tight", facecolor="white"); plt.close(fig)

# ---------------------------------------------------------------- 4. existing vs proposed
fig, ax = canvas(13, 6.0)
ax.text(0.5, 0.965, "Existing DBT-to-bank-account flow versus PurposePay", ha="center", fontsize=15, fontweight="bold")
ax.text(0.02, 0.89, "Existing (generic) flow: money is credited, then end use is not controlled", fontsize=10.5, color=RED, fontweight="bold")
ex = [("Department\nsanctions", 0.02), ("Treasury / bank\ncredit instruction", 0.215), ("Beneficiary\nbank account", 0.41), ("Cash or any\npayment", 0.605), ("Any merchant,\nany purpose", 0.80)]
for t, x in ex:
    box(ax, x, 0.64, 0.17, 0.17, t, fc="#FDECEA", ec=RED, fs=9.5)
for i in range(4): arrow(ax, (ex[i][1] + 0.172, 0.725), (ex[i + 1][1] - 0.002, 0.725), color=RED)
ax.text(0.02, 0.575, "Control is after the fact: audits, utilisation reports, grievance complaints; the ledger of record is split across institutions", fontsize=9.3, color=RED)
ax.text(0.02, 0.47, "PurposePay: the rule travels with the money and is enforced at the moment of payment", fontsize=10.5, color=TEAL, fontweight="bold")
pp = [("Department\ncreates scheme\n(category, expiry, cap)", 0.02), ("Funds locked in\nvault, allocated\nto beneficiary", 0.215), ("Beneficiary pays\nonly an eligible\nmerchant", 0.41), ("Merchant redeems\nto bank", 0.605), ("Unspent money\nreturns to treasury\nat expiry", 0.80)]
for t, x in pp:
    box(ax, x, 0.20, 0.17, 0.2, t, fc="#E4F4EF", ec=TEAL, fs=9.3)
for i in range(4): arrow(ax, (pp[i][1] + 0.172, 0.30), (pp[i + 1][1] - 0.002, 0.30), color=TEAL)
ax.text(0.02, 0.12, "One shared, append-only ledger: every institution and auditor reads the same events (Allocated, Spent, Redeemed, Reclaimed)", fontsize=9.3, color=TEAL)
fig.savefig("diagrams/comparison.png", dpi=170, bbox_inches="tight", facecolor="white"); plt.close(fig)
print("diagrams done")
